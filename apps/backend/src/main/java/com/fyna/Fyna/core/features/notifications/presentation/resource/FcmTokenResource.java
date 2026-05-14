package com.fyna.Fyna.core.features.notifications.presentation.resource;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.notifications.domain.service.FcmTokenService;
import com.fyna.Fyna.core.features.notifications.presentation.dto.RegisterFcmTokenRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/fcm")
public class FcmTokenResource {

    private final FcmTokenService fcmTokenService;
    private final SecurityUtils securityUtils;

    public FcmTokenResource(FcmTokenService fcmTokenService, SecurityUtils securityUtils) {
        this.fcmTokenService = fcmTokenService;
        this.securityUtils = securityUtils;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<Void>> register(@Valid @RequestBody RegisterFcmTokenRequest request) {
        fcmTokenService.register(
                securityUtils.getCurrentUserId(),
                request.token(),
                request.deviceType(),
                request.deviceId()
        );
        return ResponseEntity.ok(ApiResponse.ok(null));
    }

    @DeleteMapping("/{token}")
    public ResponseEntity<Void> unregister(@PathVariable String token) {
        fcmTokenService.unregister(token);
        return ResponseEntity.noContent().build();
    }
}
