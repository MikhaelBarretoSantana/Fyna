package com.fyna.Fyna.core.features.users.presentation.dto;

import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.UserStatus;

public record UserResponse(
        UUID id,
        String login,
        String email,
        String fullName,
        String phone,
        String avatarUrl,
        LocalDate birthDate,
        UserStatus status,
        boolean emailVerified
) {
    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getLogin(),
                user.getEmail(),
                user.getFullName(),
                user.getPhone(),
                user.getAvatarUrl(),
                user.getBirthDate(),
                user.getStatus(),
                user.getEmailVerified()
        );
    }
}
