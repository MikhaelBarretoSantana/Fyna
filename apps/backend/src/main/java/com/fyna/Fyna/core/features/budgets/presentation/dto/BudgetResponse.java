package com.fyna.Fyna.core.features.budgets.presentation.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.Budget;
import com.fyna.Fyna.core.shared.enums.BudgetPeriodType;

public record BudgetResponse(
        UUID id,
        UUID categoryId,
        String categoryName,
        String name,
        BigDecimal amountLimit,
        BigDecimal amountSpent,
        BigDecimal remainingAmount,
        double percentUsed,
        BudgetPeriodType periodType,
        LocalDate startDate,
        LocalDate endDate,
        BigDecimal alertThreshold,
        boolean alertEnabled,
        boolean isActive
) {
    public static BudgetResponse from(Budget budget) {
        BigDecimal remaining = budget.getAmountLimit().subtract(budget.getAmountSpent());
        double percent = budget.getAmountLimit().compareTo(BigDecimal.ZERO) > 0
                ? budget.getAmountSpent().doubleValue() / budget.getAmountLimit().doubleValue() * 100.0
                : 0.0;

        return new BudgetResponse(
                budget.getId(),
                budget.getCategory() != null ? budget.getCategory().getId() : null,
                budget.getCategory() != null ? budget.getCategory().getName() : null,
                budget.getName(),
                budget.getAmountLimit(),
                budget.getAmountSpent(),
                remaining,
                Math.round(percent * 100.0) / 100.0,
                budget.getPeriodType(),
                budget.getStartDate(),
                budget.getEndDate(),
                budget.getAlertThreshold(),
                budget.getAlertEnabled(),
                budget.getIsActive()
        );
    }
}
