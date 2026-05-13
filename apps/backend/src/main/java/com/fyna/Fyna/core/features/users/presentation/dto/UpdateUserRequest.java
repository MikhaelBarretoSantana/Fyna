package com.fyna.Fyna.core.features.users.presentation.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @Size(max = 255, message = "Nome deve ter no máximo 255 caracteres")
        String fullName,

        @Email(message = "Email inválido")
        @Size(max = 255, message = "Email deve ter no máximo 255 caracteres")
        String email,

        @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
        String phone,

        @Size(max = 500, message = "URL do avatar deve ter no máximo 500 caracteres")
        String avatarUrl,

        LocalDate birthDate
) {
}
