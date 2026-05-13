package com.fyna.Fyna.core.features.goals.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.FinancialGoal;
import com.fyna.Fyna.core.shared.enums.FinancialGoalPriority;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

public record FinancialGoalResponse(
        UUID id,
        String name,
        String description,
        String icon,
        String color,
        BigDecimal targetAmount,
        BigDecimal currentAmount,
        double progressPercent,
        LocalDate targetDate,
        FinancialGoalStatus status,
        FinancialGoalPriority priority,
        Instant completedAt,
        Instant createdAt
) {
    public static FinancialGoalResponse from(FinancialGoal goal) {
        double progress = goal.getTargetAmount().compareTo(BigDecimal.ZERO) > 0
                ? goal.getCurrentAmount().doubleValue() / goal.getTargetAmount().doubleValue() * 100.0
                : 0.0;

        return new FinancialGoalResponse(
                goal.getId(),
                goal.getName(),
                goal.getDescription(),
                goal.getIcon(),
                goal.getColor(),
                goal.getTargetAmount(),
                goal.getCurrentAmount(),
                Math.round(progress * 100.0) / 100.0,
                goal.getTargetDate(),
                goal.getStatus(),
                goal.getPriority(),
                goal.getCompletedAt(),
                goal.getCreatedAt()
        );
    }
}
