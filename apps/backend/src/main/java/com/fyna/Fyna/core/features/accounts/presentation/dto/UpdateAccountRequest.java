package com.fyna.Fyna.core.features.accounts.presentation.dto;

import java.math.BigDecimal;

import com.fyna.Fyna.core.shared.enums.AccountTypes;

import jakarta.validation.constraints.Size;

public record UpdateAccountRequest(
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        AccountTypes type,

        @Size(max = 100, message = "Instituição deve ter no máximo 100 caracteres")
        String institution,

        @Size(max = 7, message = "Cor deve ter no máximo 7 caracteres")
        String color,

        @Size(max = 50, message = "Ícone deve ter no máximo 50 caracteres")
        String icon,

        BigDecimal currentBalance,

        Boolean isActive,

        Boolean includeInTotal
) {
}
