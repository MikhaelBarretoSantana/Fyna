package com.fyna.Fyna.core.features.auth.domain.service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.Period;
import java.util.HexFormat;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.UnauthorizedException;
import com.fyna.Fyna.core.features.auth.data.repository.RefreshTokenRepository;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.auth.presentation.dto.AuthResponse;
import com.fyna.Fyna.core.features.auth.presentation.dto.LoginRequest;
import com.fyna.Fyna.core.features.auth.presentation.dto.RefreshTokenRequest;
import com.fyna.Fyna.core.features.auth.presentation.dto.RegisterRequest;
import com.fyna.Fyna.core.security.JwtTokenProvider;
import com.fyna.Fyna.core.shared.domain.RefreshTokens;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.domain.UserPreferences;
import com.fyna.Fyna.core.shared.enums.UserStatus;
import com.fyna.Fyna.core.features.users.data.repository.UserPreferencesRepository;

@Service
public class AuthService {

    /** Idade mínima exigida para registro (compliance fintech). */
    private static final int MIN_AGE_YEARS = 18;

    private final UserRepository userRepository;
    private final RefreshTokenRepository refreshTokenRepository;
    private final UserPreferencesRepository userPreferencesRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final AuthenticationManager authenticationManager;
    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository userRepository, RefreshTokenRepository refreshTokenRepository,
            UserPreferencesRepository userPreferencesRepository, JwtTokenProvider jwtTokenProvider,
            AuthenticationManager authenticationManager, PasswordEncoder passwordEncoder) {
        this.userRepository = userRepository;
        this.refreshTokenRepository = refreshTokenRepository;
        this.userPreferencesRepository = userPreferencesRepository;
        this.jwtTokenProvider = jwtTokenProvider;
        this.authenticationManager = authenticationManager;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByLogin(request.login())) {
            throw new BadRequestException("Login já está em uso");
        }
        if (userRepository.existsByEmail(request.email())) {
            throw new BadRequestException("Email já está em uso");
        }
        if (request.birthDate() != null) {
            LocalDate today = LocalDate.now();
            if (request.birthDate().isAfter(today)) {
                throw new BadRequestException("Data de nascimento não pode estar no futuro");
            }
            int years = Period.between(request.birthDate(), today).getYears();
            if (years < MIN_AGE_YEARS) {
                throw new BadRequestException(
                        "É necessário ter pelo menos " + MIN_AGE_YEARS + " anos para se cadastrar");
            }
        }

        User user = new User();
        user.setLogin(request.login());
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        user.setFullName(request.fullName());
        user.setPhone(request.phone());
        if (request.birthDate() != null) {
            user.setBirthDate(request.birthDate());
        }
        user.setStatus(UserStatus.ACTIVE);
        user.setEmailVerified(false);

        user = userRepository.save(user);

        UserPreferences preferences = UserPreferences.builder()
                .user(user)
                .build();
        userPreferencesRepository.save(preferences);

        return generateAuthResponse(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.login(), request.password()));

        User user = userRepository.findByLogin(request.login())
                .orElseThrow(() -> new UnauthorizedException("Credenciais inválidas"));

        return generateAuthResponse(user);
    }

    /**
     * Rotaciona o refresh token de forma atômica. Em refresh paralelos com o mesmo
     * token, somente uma chamada vence o update condicional; as demais recebem 401.
     * Token reutilizado depois de revogado também derruba todas as sessões do usuário
     * (heurística de detecção de roubo).
     */
    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String tokenHash = hashToken(request.refreshToken());

        RefreshTokens refreshToken = refreshTokenRepository.findByTokenHash(tokenHash)
                .orElseThrow(() -> new UnauthorizedException("Refresh token inválido"));

        Instant now = Instant.now();

        // Reuse de token já revogado → possível roubo. Revoga toda a árvore do usuário.
        if (Boolean.TRUE.equals(refreshToken.getIsRevoked())) {
            refreshTokenRepository.revokeAllByUserId(refreshToken.getUser().getId(), now);
            throw new UnauthorizedException("Refresh token inválido");
        }

        if (refreshToken.getExpiresAt().isBefore(now)) {
            refreshTokenRepository.revokeIfActive(tokenHash, now);
            throw new UnauthorizedException("Refresh token expirado");
        }

        // Revogação atômica: apenas uma chamada concorrente consegue marcar isRevoked=true.
        int revoked = refreshTokenRepository.revokeIfActive(tokenHash, now);
        if (revoked == 0) {
            throw new UnauthorizedException("Refresh token inválido");
        }

        User user = refreshToken.getUser();
        return generateAuthResponse(user);
    }

    /**
     * Logout global do usuário: revoga todas as sessões em todos os devices.
     * Útil para "sign out everywhere" ou em resposta a suspeita de roubo de credencial.
     */
    @Transactional
    public void logout(java.util.UUID userId) {
        refreshTokenRepository.revokeAllByUserId(userId, Instant.now());
    }

    /**
     * Logout apenas do device corrente: revoga somente o refresh token apresentado.
     * Outros devices continuam autenticados. Se o token não existe ou já foi revogado,
     * a operação é idempotente (sem erro), evitando vazar informação sobre validade.
     */
    @Transactional
    public void logoutDevice(java.util.UUID userId, String rawRefreshToken) {
        if (rawRefreshToken == null || rawRefreshToken.isBlank()) {
            throw new BadRequestException("refreshToken é obrigatório para logout de device");
        }
        String tokenHash = hashToken(rawRefreshToken);
        RefreshTokens token = refreshTokenRepository.findByTokenHash(tokenHash).orElse(null);
        if (token == null) return; // idempotente
        if (!token.getUser().getId().equals(userId)) {
            // Token pertence a outro usuário — não vazamos isso; só ignoramos.
            return;
        }
        refreshTokenRepository.revokeIfActive(tokenHash, Instant.now());
    }

    private AuthResponse generateAuthResponse(User user) {
        String accessToken = jwtTokenProvider.generateAccessToken(user.getId(), user.getLogin());
        String rawRefreshToken = jwtTokenProvider.generateRefreshToken();
        String tokenHash = hashToken(rawRefreshToken);

        RefreshTokens refreshToken = new RefreshTokens();
        refreshToken.setUser(user);
        refreshToken.setTokenHash(tokenHash);
        refreshToken.setExpiresAt(Instant.now().plusMillis(jwtTokenProvider.getRefreshTokenExpirationMs()));
        refreshToken.setIsRevoked(false);

        refreshTokenRepository.save(refreshToken);

        AuthResponse.UserInfo userInfo = new AuthResponse.UserInfo(
                user.getId().toString(),
                user.getLogin(),
                user.getEmail(),
                user.getFullName()
        );

        return new AuthResponse(accessToken, rawRefreshToken, userInfo);
    }

    private String hashToken(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Erro ao gerar hash do token", e);
        }
    }
}
