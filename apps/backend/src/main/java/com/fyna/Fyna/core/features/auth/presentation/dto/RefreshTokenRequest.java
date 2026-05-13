package com.fyna.Fyna.core.features.auth.presentation.dto;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequest(
        @NotBlank(message = "Refresh token é obrigatório")
        String refreshToken
) {
}
