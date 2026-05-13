package com.fyna.Fyna.core.features.risk.presentation.dto;

import java.math.BigDecimal;

import com.fyna.Fyna.core.shared.enums.RiskTolerance;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CreateRiskProfileRequest(
        @NotNull(message = "Tolerância ao risco é obrigatória")
        RiskTolerance riskTolerance,

        @NotNull(message = "Horizonte de investimento é obrigatório")
        @Positive(message = "Horizonte deve ser positivo")
        Integer investmentHorizonYears,

        BigDecimal monthlyIncome,

        BigDecimal monthlyExpenses,

        BigDecimal emergencyFund,

        BigDecimal totalInvestments,

        String questionnaireAnswers
) {
}
