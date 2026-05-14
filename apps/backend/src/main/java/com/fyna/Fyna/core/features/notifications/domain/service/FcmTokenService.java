package com.fyna.Fyna.core.features.notifications.domain.service;

import java.time.Instant;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.notifications.data.repository.FcmTokenRepository;
import com.fyna.Fyna.core.shared.domain.FcmToken;
import com.fyna.Fyna.core.shared.domain.User;

@Service
public class FcmTokenService {

    private final FcmTokenRepository fcmTokenRepository;
    private final UserRepository userRepository;

    public FcmTokenService(FcmTokenRepository fcmTokenRepository, UserRepository userRepository) {
        this.fcmTokenRepository = fcmTokenRepository;
        this.userRepository = userRepository;
    }

    /**
     * Registra (ou atualiza) um token FCM para o usuário autenticado.
     * Se o token já existir vinculado a OUTRO usuário (ex.: login em outro user
     * no mesmo aparelho), a propriedade é transferida e o lastSeen atualizado.
     */
    @Transactional
    public void register(UUID userId, String token, String deviceType, String deviceId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        FcmToken entity = fcmTokenRepository.findByToken(token).orElseGet(FcmToken::new);
        entity.setUser(user);
        entity.setToken(token);
        entity.setDeviceType(deviceType);
        entity.setDeviceId(deviceId);
        entity.setLastSeenAt(Instant.now());
        fcmTokenRepository.save(entity);
    }

    @Transactional
    public void unregister(String token) {
        fcmTokenRepository.deleteByToken(token);
    }
}
