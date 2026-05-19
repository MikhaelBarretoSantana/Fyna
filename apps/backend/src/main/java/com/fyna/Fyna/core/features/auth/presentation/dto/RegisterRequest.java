package com.fyna.Fyna.core.features.auth.presentation.dto;

import java.time.LocalDate;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Login é obrigatório")
        @Size(min = 3, max = 50, message = "Login deve ter entre 3 e 50 caracteres")
        String login,

        @NotBlank(message = "Email é obrigatório")
        @Email(message = "Email inválido")
        @Size(max = 255, message = "Email deve ter no máximo 255 caracteres")
        String email,

        // Exige no mínimo 8 caracteres, com pelo menos uma letra e um dígito.
        // O padrão é intencionalmente acessível: rejeita "12345678" e "password",
        // mas não obriga simbolos especiais para não atrapalhar onboarding.
        @NotBlank(message = "Senha é obrigatória")
        @Size(min = 8, max = 100, message = "Senha deve ter entre 8 e 100 caracteres")
        @Pattern(
                regexp = "^(?=.*[A-Za-z])(?=.*\\d).{8,100}$",
                message = "Senha deve conter pelo menos uma letra e um dígito"
        )
        String password,

        @NotBlank(message = "Nome completo é obrigatório")
        @Size(max = 255, message = "Nome deve ter no máximo 255 caracteres")
        String fullName,

        @Size(max = 20, message = "Telefone deve ter no máximo 20 caracteres")
        String phone,

        LocalDate birthDate
) {
}
