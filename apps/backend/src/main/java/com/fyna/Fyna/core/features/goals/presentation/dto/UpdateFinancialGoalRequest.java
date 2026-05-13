package com.fyna.Fyna.core.features.goals.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

import com.fyna.Fyna.core.shared.enums.FinancialGoalPriority;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record UpdateFinancialGoalRequest(
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        String description,

        @Size(max = 50, message = "Ícone deve ter no máximo 50 caracteres")
        String icon,

        @Size(max = 7, message = "Cor deve ter no máximo 7 caracteres")
        String color,

        @Positive(message = "Valor alvo deve ser positivo")
        BigDecimal targetAmount,

        @Positive(message = "Valor atual deve ser positivo")
        BigDecimal currentAmount,

        LocalDate targetDate,

        FinancialGoalStatus status,

        FinancialGoalPriority priority
) {
}
