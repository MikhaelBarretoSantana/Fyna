package com.fyna.Fyna.core.features.risk.presentation.dto;

import java.math.BigDecimal;

import com.fyna.Fyna.core.shared.enums.RiskTolerance;

import jakarta.validation.constraints.Positive;

public record UpdateRiskProfileRequest(
        RiskTolerance riskTolerance,

        @Positive(message = "Horizonte deve ser positivo")
        Integer investmentHorizonYears,

        BigDecimal monthlyIncome,

        BigDecimal monthlyExpenses,

        BigDecimal emergencyFund,

        BigDecimal totalInvestments,

        String questionnaireAnswers
) {
}
