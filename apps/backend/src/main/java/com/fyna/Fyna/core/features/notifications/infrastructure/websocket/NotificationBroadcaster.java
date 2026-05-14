package com.fyna.Fyna.core.features.notifications.infrastructure.websocket;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import com.fyna.Fyna.core.features.notifications.presentation.dto.NotificationResponse;

/**
 * Broadcast in-app de notificações para o usuário conectado via STOMP.
 * O cliente assina a fila {@code /user/queue/notifications} — o Spring resolve
 * automaticamente para o {@link java.security.Principal} setado no CONNECT.
 *
 * Em ambientes sem cliente conectado, a mensagem é simplesmente descartada
 * pelo broker simples — não há fila persistente. Para entrega offline, o
 * cliente busca via REST ao reabrir o app.
 */
@Component
public class NotificationBroadcaster {

    private static final Logger log = LoggerFactory.getLogger(NotificationBroadcaster.class);
    private static final String DESTINATION = "/queue/notifications";

    private final SimpMessagingTemplate messagingTemplate;

    public NotificationBroadcaster(SimpMessagingTemplate messagingTemplate) {
        this.messagingTemplate = messagingTemplate;
    }

    public void broadcastToUser(UUID userId, NotificationResponse notification) {
        try {
            messagingTemplate.convertAndSendToUser(userId.toString(), DESTINATION, notification);
            log.debug("Notificação {} entregue via WS para user {}", notification.id(), userId);
        } catch (Exception e) {
            log.warn("Falha ao entregar via WS para user {}: {}", userId, e.getMessage());
        }
    }
}
