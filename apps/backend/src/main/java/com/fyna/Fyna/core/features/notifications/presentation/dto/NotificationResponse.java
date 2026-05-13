package com.fyna.Fyna.core.features.notifications.presentation.dto;

import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.Notification;
import com.fyna.Fyna.core.shared.enums.NotificationType;

public record NotificationResponse(
        UUID id,
        NotificationType type,
        String title,
        String message,
        String actionUrl,
        String metadata,
        boolean isRead,
        Instant readAt,
        Instant scheduledFor,
        Instant createdAt
) {
    public static NotificationResponse from(Notification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getType(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getActionUrl(),
                notification.getMetadata(),
                notification.getIsRead(),
                notification.getReadAt(),
                notification.getScheduledFor(),
                notification.getCreatedAt()
        );
    }
}
