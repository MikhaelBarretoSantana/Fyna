package com.fyna.Fyna.core.features.recurring.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.RecurringTransactions;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsFrequencyTypes;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes;

public record RecurringTransactionResponse(
        UUID id,
        UUID accountId,
        UUID categoryId,
        String categoryName,
        RecurringTransactionsTypes type,
        BigDecimal amount,
        String description,
        RecurringTransactionsFrequencyTypes frequency,
        int frequencyInterval,
        LocalDate startDate,
        LocalDate endDate,
        LocalDate nextOccurrence,
        LocalDate lastGenerated,
        boolean isActive
) {
    public static RecurringTransactionResponse from(RecurringTransactions rt) {
        return new RecurringTransactionResponse(
                rt.getId(),
                rt.getAccount() != null ? rt.getAccount().getId() : null,
                rt.getCategories() != null ? rt.getCategories().getId() : null,
                rt.getCategories() != null ? rt.getCategories().getName() : null,
                rt.getType(),
                rt.getAmount(),
                rt.getDescription(),
                rt.getFrequency(),
                rt.getFrequencyInterval(),
                rt.getStartDate(),
                rt.getEndDate(),
                rt.getNextOccurrence(),
                rt.getLastGenerated(),
                rt.getIsActive()
        );
    }
}
