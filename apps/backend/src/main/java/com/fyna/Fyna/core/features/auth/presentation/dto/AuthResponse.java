package com.fyna.Fyna.core.features.auth.presentation.dto;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        String tokenType,
        UserInfo user
) {
    public AuthResponse(String accessToken, String refreshToken, UserInfo user) {
        this(accessToken, refreshToken, "Bearer", user);
    }

    public record UserInfo(
            String id,
            String login,
            String email,
            String fullName
    ) {
    }
}
