package com.fyna.Fyna.core.features.transactions.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.TransactionsType;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record CreateTransactionRequest(
        @NotNull(message = "Conta é obrigatória")
        UUID accountId,

        UUID categoryId,

        @NotNull(message = "Tipo é obrigatório")
        TransactionsType type,

        @NotNull(message = "Valor é obrigatório")
        @Positive(message = "Valor deve ser positivo")
        BigDecimal amount,

        @NotBlank(message = "Descrição é obrigatória")
        @Size(max = 255, message = "Descrição deve ter no máximo 255 caracteres")
        String description,

        String notes,

        @NotNull(message = "Data da transação é obrigatória")
        LocalDate transactionDate,

        LocalDate dueDate,

        Boolean isPaid,

        @Size(max = 500, message = "URL do anexo deve ter no máximo 500 caracteres")
        String attachmentUrl,

        UUID transferAccountId
) {
}
