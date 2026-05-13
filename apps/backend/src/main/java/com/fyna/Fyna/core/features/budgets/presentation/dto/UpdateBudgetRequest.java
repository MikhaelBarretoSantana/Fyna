package com.fyna.Fyna.core.features.budgets.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record UpdateBudgetRequest(
        UUID categoryId,

        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        @Positive(message = "Limite deve ser positivo")
        BigDecimal amountLimit,

        LocalDate endDate,

        BigDecimal alertThreshold,

        Boolean alertEnabled,

        Boolean isActive
) {
}
