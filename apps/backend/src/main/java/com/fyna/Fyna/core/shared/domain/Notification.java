package com.fyna.Fyna.core.shared.domain;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.NotificationType;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "notifications", indexes = {
        @Index(name = "idx_notifications_user_id", columnList = "user_id"),
        @Index(name = "idx_notifications_type", columnList = "type"),
        @Index(name = "idx_notifications_is_read", columnList = "is_read"),
        @Index(name = "idx_notifications_created_at", columnList = "created_at"),
        @Index(name = "idx_notifications_scheduled_for", columnList = "scheduled_for"),
        @Index(name = "idx_notifications_user_unread", columnList = "user_id,is_read,created_at DESC")
})
public class Notification implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 30, nullable = false)
    private NotificationType type;

    @Column(name = "title", length = 200, nullable = false)
    private String title;

    @Column(name = "message", columnDefinition = "TEXT", nullable = false)
    private String message;

    @Column(name = "action_url", length = 500)
    private String actionUrl;

    @Column(name = "metadata", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String metadata;

    @Column(name = "is_read", nullable = false)
    private Boolean isRead = false;

    @Column(name = "is_pushed", nullable = false)
    private Boolean isPushed = false;

    @Column(name = "read_at")
    private Instant readAt;

    @Column(name = "scheduled_for")
    private Instant scheduledFor;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    public Notification() {
    }

    public Notification(UUID id, User user, NotificationType type, String title, String message,
            String actionUrl, String metadata, Boolean isRead, Boolean isPushed, Instant readAt,
            Instant scheduledFor) {
        this.id = id;
        this.user = user;
        this.type = type;
        this.title = title;
        this.message = message;
        this.actionUrl = actionUrl;
        this.metadata = metadata;
        this.isRead = isRead;
        this.isPushed = isPushed;
        this.readAt = readAt;
        this.scheduledFor = scheduledFor;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public NotificationType getType() {
        return type;
    }

    public void setType(NotificationType type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getActionUrl() {
        return actionUrl;
    }

    public void setActionUrl(String actionUrl) {
        this.actionUrl = actionUrl;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public Boolean getIsRead() {
        return isRead;
    }

    public void setIsRead(Boolean isRead) {
        this.isRead = isRead;
    }

    public Boolean getIsPushed() {
        return isPushed;
    }

    public void setIsPushed(Boolean isPushed) {
        this.isPushed = isPushed;
    }

    public Instant getReadAt() {
        return readAt;
    }

    public void setReadAt(Instant readAt) {
        this.readAt = readAt;
    }

    public Instant getScheduledFor() {
        return scheduledFor;
    }

    public void setScheduledFor(Instant scheduledFor) {
        this.scheduledFor = scheduledFor;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }
}
