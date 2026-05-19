package com.fyna.Fyna.core.features.recurring.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.RecurringTransactionsFrequencyTypes;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateRecurringTransactionRequest(
        @NotNull(message = "Conta é obrigatória")
        UUID accountId,

        /** Obrigatório quando {@code type == TRANSFER}; ignorado para INCOME/EXPENSE. */
        UUID transferAccountId,

        UUID categoryId,

        @NotNull(message = "Tipo é obrigatório")
        RecurringTransactionsTypes type,

        @NotNull(message = "Valor é obrigatório")
        @Positive(message = "Valor deve ser positivo")
        BigDecimal amount,

        @NotBlank(message = "Descrição é obrigatória")
        @Size(max = 255, message = "Descrição deve ter no máximo 255 caracteres")
        String description,

        @NotNull(message = "Frequência é obrigatória")
        RecurringTransactionsFrequencyTypes frequency,

        @Positive(message = "Intervalo deve ser positivo")
        Integer frequencyInterval,

        @NotNull(message = "Data de início é obrigatória")
        LocalDate startDate,

        LocalDate endDate
) {
}
