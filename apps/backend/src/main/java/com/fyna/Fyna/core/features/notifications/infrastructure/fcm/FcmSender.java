package com.fyna.Fyna.core.features.notifications.infrastructure.fcm;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

import com.fyna.Fyna.core.features.notifications.data.repository.FcmTokenRepository;
import com.fyna.Fyna.core.shared.domain.FcmToken;
import com.fyna.Fyna.core.shared.domain.Notification;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.MessagingErrorCode;

import jakarta.annotation.Nullable;

/**
 * Envio assíncrono de push notifications para todos os tokens FCM de um usuário.
 * Quando o bean {@link FirebaseMessaging} não estiver disponível (sem credenciais),
 * o método {@link #sendToUser(UUID, Notification)} apenas loga e retorna — não
 * derruba o fluxo de criação de notificação.
 *
 * Tokens recusados pelo Firebase (UNREGISTERED / INVALID_ARGUMENT) são removidos
 * automaticamente do banco para evitar tentativas repetidas.
 */
@Component
public class FcmSender {

    private static final Logger log = LoggerFactory.getLogger(FcmSender.class);

    private final FirebaseMessaging firebaseMessaging;
    private final FcmTokenRepository fcmTokenRepository;

    public FcmSender(@Autowired(required = false) @Nullable FirebaseMessaging firebaseMessaging,
            FcmTokenRepository fcmTokenRepository) {
        this.firebaseMessaging = firebaseMessaging;
        this.fcmTokenRepository = fcmTokenRepository;
    }

    public boolean isEnabled() {
        return firebaseMessaging != null;
    }

    @Async
    public void sendToUser(UUID userId, Notification notification) {
        if (!isEnabled()) {
            log.debug("FCM desabilitado — pulando push para usuário {}", userId);
            return;
        }

        List<FcmToken> tokens = fcmTokenRepository.findByUserId(userId);
        if (tokens.isEmpty()) {
            log.debug("Sem tokens FCM para usuário {}", userId);
            return;
        }

        Map<String, String> data = new HashMap<>();
        data.put("notificationId", notification.getId().toString());
        data.put("type", notification.getType().name());
        if (notification.getActionUrl() != null) data.put("actionUrl", notification.getActionUrl());
        if (notification.getMetadata() != null) data.put("metadata", notification.getMetadata());

        for (FcmToken fcmToken : tokens) {
            try {
                Message message = Message.builder()
                        .setToken(fcmToken.getToken())
                        .setNotification(com.google.firebase.messaging.Notification.builder()
                                .setTitle(notification.getTitle())
                                .setBody(notification.getMessage())
                                .build())
                        .putAllData(data)
                        .build();
                firebaseMessaging.send(message);
                log.debug("Push enviado para token {}", maskToken(fcmToken.getToken()));
            } catch (FirebaseMessagingException e) {
                handleSendFailure(fcmToken, e);
            } catch (Exception e) {
                log.warn("Falha inesperada ao enviar push para token {}: {}",
                        maskToken(fcmToken.getToken()), e.getMessage());
            }
        }
    }

    private void handleSendFailure(FcmToken fcmToken, FirebaseMessagingException e) {
        MessagingErrorCode code = e.getMessagingErrorCode();
        if (code == MessagingErrorCode.UNREGISTERED || code == MessagingErrorCode.INVALID_ARGUMENT) {
            log.info("Token FCM inválido ({}). Removendo: {}", code, maskToken(fcmToken.getToken()));
            fcmTokenRepository.deleteByToken(fcmToken.getToken());
        } else {
            log.warn("Falha FCM (code={}) para token {}: {}",
                    code, maskToken(fcmToken.getToken()), e.getMessage());
        }
    }

    private static String maskToken(String token) {
        if (token == null || token.length() <= 8) return "***";
        return token.substring(0, 4) + "..." + token.substring(token.length() - 4);
    }
}
