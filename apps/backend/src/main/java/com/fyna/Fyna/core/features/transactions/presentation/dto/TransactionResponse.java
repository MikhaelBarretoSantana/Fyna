package com.fyna.Fyna.core.features.transactions.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

public record TransactionResponse(
        UUID id,
        UUID accountId,
        UUID categoryId,
        String categoryName,
        UUID transferPairId,
        TransactionsType type,
        BigDecimal amount,
        String description,
        String notes,
        LocalDate transactionDate,
        LocalDate dueDate,
        boolean isPaid,
        boolean isRecurring,
        UUID recurringTransactionId,
        String attachmentUrl
) {
    public static TransactionResponse from(Transactions transaction) {
        return new TransactionResponse(
                transaction.getId(),
                transaction.getAccount() != null ? transaction.getAccount().getId() : null,
                transaction.getCategories() != null ? transaction.getCategories().getId() : null,
                transaction.getCategories() != null ? transaction.getCategories().getName() : null,
                transaction.getTransactions() != null ? transaction.getTransactions().getId() : null,
                transaction.getType(),
                transaction.getAmount(),
                transaction.getDescription(),
                transaction.getNotes(),
                transaction.getTransactionDate(),
                transaction.getDueDate(),
                transaction.getIsPaid(),
                transaction.getIsRecurring(),
                transaction.getRecurringTransactions() != null ? transaction.getRecurringTransactions().getId() : null,
                transaction.getAttachmentUrl()
        );
    }
}
