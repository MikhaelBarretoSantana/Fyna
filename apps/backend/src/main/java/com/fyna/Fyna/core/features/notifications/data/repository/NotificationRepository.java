package com.fyna.Fyna.core.features.notifications.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.Notification;
import com.fyna.Fyna.core.shared.enums.NotificationType;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, UUID> {

    Page<Notification> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);

    List<Notification> findByUserIdAndIsReadFalseOrderByCreatedAtDesc(UUID userId);

    Optional<Notification> findByIdAndUserId(UUID id, UUID userId);

    long countByUserIdAndIsReadFalse(UUID userId);

    List<Notification> findByUserIdAndTypeOrderByCreatedAtDesc(UUID userId, NotificationType type);

    @Modifying
    @Query("UPDATE Notification n SET n.isRead = true, n.readAt = CURRENT_TIMESTAMP " +
            "WHERE n.user.id = :userId AND n.isRead = false")
    int markAllAsRead(@Param("userId") UUID userId);
}
