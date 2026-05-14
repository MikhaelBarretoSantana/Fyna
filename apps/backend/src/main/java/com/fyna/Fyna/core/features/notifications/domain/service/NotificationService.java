package com.fyna.Fyna.core.features.notifications.domain.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.notifications.data.repository.NotificationRepository;
import com.fyna.Fyna.core.features.notifications.infrastructure.fcm.FcmSender;
import com.fyna.Fyna.core.features.notifications.infrastructure.websocket.NotificationBroadcaster;
import com.fyna.Fyna.core.features.notifications.presentation.dto.NotificationResponse;
import com.fyna.Fyna.core.shared.domain.Notification;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.NotificationType;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final FcmSender fcmSender;
    private final NotificationBroadcaster broadcaster;

    public NotificationService(NotificationRepository notificationRepository, UserRepository userRepository,
            FcmSender fcmSender, NotificationBroadcaster broadcaster) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.fcmSender = fcmSender;
        this.broadcaster = broadcaster;
    }

    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getNotifications(UUID userId, Pageable pageable) {
        Page<NotificationResponse> page = notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId, pageable)
                .map(NotificationResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getUnreadNotifications(UUID userId) {
        return notificationRepository.findByUserIdAndIsReadFalseOrderByCreatedAtDesc(userId).stream()
                .map(NotificationResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public long getUnreadCount(UUID userId) {
        return notificationRepository.countByUserIdAndIsReadFalse(userId);
    }

    @Transactional
    public NotificationResponse markAsRead(UUID id, UUID userId) {
        Notification notification = notificationRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", "id", id));
        notification.setIsRead(true);
        notification.setReadAt(Instant.now());
        notification = notificationRepository.save(notification);
        return NotificationResponse.from(notification);
    }

    @Transactional
    public int markAllAsRead(UUID userId) {
        return notificationRepository.markAllAsRead(userId);
    }

    @Transactional
    public void deleteNotification(UUID id, UUID userId) {
        Notification notification = notificationRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification", "id", id));
        notificationRepository.delete(notification);
    }

    /**
     * Cria uma notificação para um usuário.
     * Pode ser chamado internamente pelo serviço ou por outros serviços (ex: IA).
     */
    @Transactional
    public NotificationResponse createNotification(UUID userId, NotificationType type, String title,
            String message, String actionUrl, String metadata) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Notification notification = new Notification();
        notification.setUser(user);
        notification.setType(type);
        notification.setTitle(title);
        notification.setMessage(message);
        notification.setActionUrl(actionUrl);
        notification.setMetadata(metadata);
        notification.setIsRead(false);
        notification.setIsPushed(false);

        notification = notificationRepository.save(notification);
        NotificationResponse response = NotificationResponse.from(notification);

        // Entrega in-app via WebSocket — chega instantaneamente se o app estiver conectado.
        broadcaster.broadcastToUser(userId, response);

        // Push assíncrono via FCM — entrega mesmo com app fechado.
        // Se o Firebase não estiver configurado, vira no-op.
        fcmSender.sendToUser(userId, notification);

        return response;
    }
}
