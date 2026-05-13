package com.fyna.Fyna.core.features.recurring.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record UpdateRecurringTransactionRequest(
        UUID categoryId,

        @Positive(message = "Valor deve ser positivo")
        BigDecimal amount,

        @Size(max = 255, message = "Descrição deve ter no máximo 255 caracteres")
        String description,

        LocalDate endDate,

        Boolean isActive
) {
}
