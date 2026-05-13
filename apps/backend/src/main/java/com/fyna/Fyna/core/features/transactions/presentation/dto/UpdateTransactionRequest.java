package com.fyna.Fyna.core.features.transactions.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record UpdateTransactionRequest(
        UUID categoryId,

        @Positive(message = "Valor deve ser positivo")
        BigDecimal amount,

        @Size(max = 255, message = "Descrição deve ter no máximo 255 caracteres")
        String description,

        String notes,

        LocalDate transactionDate,

        LocalDate dueDate,

        Boolean isPaid,

        @Size(max = 500, message = "URL do anexo deve ter no máximo 500 caracteres")
        String attachmentUrl
) {
}
