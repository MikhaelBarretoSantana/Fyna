package com.fyna.Fyna.core.features.notifications.presentation.resource;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.features.notifications.presentation.dto.NotificationResponse;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;
import com.fyna.Fyna.core.shared.dto.PageResponse;

@RestController
@RequestMapping("/api/v1/notifications")
public class NotificationResource {

    private final NotificationService notificationService;
    private final SecurityUtils securityUtils;

    public NotificationResource(NotificationService notificationService, SecurityUtils securityUtils) {
        this.notificationService = notificationService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<NotificationResponse>>> getNotifications(
            @PageableDefault(size = 20) Pageable pageable) {
        PageResponse<NotificationResponse> response =
                notificationService.getNotifications(securityUtils.getCurrentUserId(), pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/unread")
    public ResponseEntity<ApiResponse<List<NotificationResponse>>> getUnreadNotifications() {
        List<NotificationResponse> response =
                notificationService.getUnreadNotifications(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/unread/count")
    public ResponseEntity<ApiResponse<Map<String, Long>>> getUnreadCount() {
        long count = notificationService.getUnreadCount(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("count", count)));
    }

    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(@PathVariable UUID id) {
        NotificationResponse response = notificationService.markAsRead(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<Map<String, Integer>>> markAllAsRead() {
        int updated = notificationService.markAllAsRead(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(Map.of("updated", updated)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteNotification(@PathVariable UUID id) {
        notificationService.deleteNotification(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
