package com.fyna.Fyna.core.features.budgets.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.BudgetPeriodType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateBudgetRequest(
        UUID categoryId,

        @NotBlank(message = "Nome é obrigatório")
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        @NotNull(message = "Limite é obrigatório")
        @Positive(message = "Limite deve ser positivo")
        BigDecimal amountLimit,

        @NotNull(message = "Tipo de período é obrigatório")
        BudgetPeriodType periodType,

        @NotNull(message = "Data de início é obrigatória")
        LocalDate startDate,

        @NotNull(message = "Data de fim é obrigatória")
        LocalDate endDate,

        BigDecimal alertThreshold,

        Boolean alertEnabled
) {
}
