package com.fyna.Fyna.core.features.notifications.presentation.dto;

import jakarta.validation.constraints.NotBlank;

public record RegisterFcmTokenRequest(
        @NotBlank String token,
        String deviceType,
        String deviceId
) {
}
