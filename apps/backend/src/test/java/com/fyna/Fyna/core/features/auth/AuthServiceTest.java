package com.fyna.Fyna.core.features.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.UnauthorizedException;
import com.fyna.Fyna.core.features.auth.data.repository.RefreshTokenRepository;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.auth.domain.service.AuthService;
import com.fyna.Fyna.core.features.auth.presentation.dto.LoginRequest;
import com.fyna.Fyna.core.features.auth.presentation.dto.RefreshTokenRequest;
import com.fyna.Fyna.core.features.auth.presentation.dto.RegisterRequest;
import com.fyna.Fyna.core.features.users.data.repository.UserPreferencesRepository;
import com.fyna.Fyna.core.security.JwtTokenProvider;
import com.fyna.Fyna.core.shared.domain.RefreshTokens;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.UserStatus;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock UserRepository userRepository;
    @Mock RefreshTokenRepository refreshTokenRepository;
    @Mock UserPreferencesRepository userPreferencesRepository;
    @Mock JwtTokenProvider jwtTokenProvider;
    @Mock AuthenticationManager authenticationManager;
    @Mock PasswordEncoder passwordEncoder;

    @InjectMocks AuthService authService;

    private User fakeUser;

    @BeforeEach
    void setUp() {
        fakeUser = new User();
        fakeUser.setId(UUID.randomUUID());
        fakeUser.setLogin("joao");
        fakeUser.setEmail("joao@email.com");
        fakeUser.setFullName("João Silva");
        fakeUser.setPassword("hashed-pass");
        fakeUser.setStatus(UserStatus.ACTIVE);
    }

    // ─── Register ───────────────────────────────────────────────────────

    @Test
    void register_deveRetornarTokensQuandoDadosValidos() {
        var request = new RegisterRequest("joao", "joao@email.com", "senha123", "João Silva", null, null);

        when(userRepository.existsByLogin("joao")).thenReturn(false);
        when(userRepository.existsByEmail("joao@email.com")).thenReturn(false);
        when(passwordEncoder.encode("senha123")).thenReturn("hashed");
        when(userRepository.save(any())).thenReturn(fakeUser);
        when(jwtTokenProvider.generateAccessToken(any(), anyString())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("refresh-raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(86400000L);
        when(refreshTokenRepository.save(any())).thenReturn(new RefreshTokens());

        var result = authService.register(request);

        assertThat(result.accessToken()).isEqualTo("access-token");
        assertThat(result.refreshToken()).isEqualTo("refresh-raw");
        verify(userPreferencesRepository).save(any());
    }

    @Test
    void register_deveLancarExcecaoQuandoLoginJaExiste() {
        var request = new RegisterRequest("joao", "joao@email.com", "senha123", "João Silva", null, null);
        when(userRepository.existsByLogin("joao")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Login já está em uso");

        verify(userRepository, never()).save(any());
    }

    @Test
    void register_deveLancarExcecaoQuandoEmailJaExiste() {
        var request = new RegisterRequest("joao2", "joao@email.com", "senha123", "João", null, null);
        when(userRepository.existsByLogin("joao2")).thenReturn(false);
        when(userRepository.existsByEmail("joao@email.com")).thenReturn(true);

        assertThatThrownBy(() -> authService.register(request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("Email já está em uso");
    }

    // ─── Login ──────────────────────────────────────────────────────────

    @Test
    void login_deveRetornarTokensComCredenciaisValidas() {
        var request = new LoginRequest("joao", "senha123");

        when(userRepository.findByLogin("joao")).thenReturn(Optional.of(fakeUser));
        when(jwtTokenProvider.generateAccessToken(any(), anyString())).thenReturn("access-token");
        when(jwtTokenProvider.generateRefreshToken()).thenReturn("refresh-raw");
        when(jwtTokenProvider.getRefreshTokenExpirationMs()).thenReturn(86400000L);
        when(refreshTokenRepository.save(any())).thenReturn(new RefreshTokens());

        var result = authService.login(request);

        assertThat(result.accessToken()).isEqualTo("access-token");
        assertThat(result.userInfo().login()).isEqualTo("joao");
    }

    @Test
    void login_deveLancarExcecaoComCredenciaisInvalidas() {
        var request = new LoginRequest("joao", "errada");
        when(authenticationManager.authenticate(any()))
                .thenThrow(new BadCredentialsException("bad credentials"));

        assertThatThrownBy(() -> authService.login(request))
                .isInstanceOf(BadCredentialsException.class);
    }

    // ─── Refresh Token ───────────────────────────────────────────────────

    @Test
    void refreshToken_deveLancarExcecaoQuandoTokenExpirado() {
        var rt = new RefreshTokens();
        rt.setUser(fakeUser);
        rt.setIsRevoked(false);
        rt.setExpiresAt(Instant.now().minusSeconds(3600));

        when(refreshTokenRepository.findByTokenHashAndIsRevokedFalse(anyString()))
                .thenReturn(Optional.of(rt));

        assertThatThrownBy(() -> authService.refreshToken(new RefreshTokenRequest("some-token")))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("expirado");
    }

    @Test
    void refreshToken_deveLancarExcecaoQuandoTokenInvalido() {
        when(refreshTokenRepository.findByTokenHashAndIsRevokedFalse(anyString()))
                .thenReturn(Optional.empty());

        assertThatThrownBy(() -> authService.refreshToken(new RefreshTokenRequest("invalid")))
                .isInstanceOf(UnauthorizedException.class)
                .hasMessageContaining("inválido");
    }

    // ─── Logout ─────────────────────────────────────────────────────────

    @Test
    void logout_deveRevogarTodosRefreshTokensDoUsuario() {
        UUID userId = fakeUser.getId();

        authService.logout(userId);

        verify(refreshTokenRepository).revokeAllByUserId(any(UUID.class), any(Instant.class));
    }
}
