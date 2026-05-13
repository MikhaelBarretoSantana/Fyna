package com.fyna.Fyna.core.features.risk.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.RiskProfile;
import com.fyna.Fyna.core.shared.enums.RiskTolerance;

public record RiskProfileResponse(
        UUID id,
        RiskTolerance riskTolerance,
        int investmentHorizonYears,
        BigDecimal monthlyIncome,
        BigDecimal monthlyExpenses,
        BigDecimal emergencyFund,
        BigDecimal totalInvestments,
        BigDecimal calculatedScore,
        Instant lastAssessmentAt,
        Instant createdAt
) {
    public static RiskProfileResponse from(RiskProfile profile) {
        return new RiskProfileResponse(
                profile.getId(),
                profile.getRiskTolerance(),
                profile.getInvestmentHorizonYears(),
                profile.getMonthlyIncome(),
                profile.getMonthlyExpenses(),
                profile.getEmergencyFund(),
                profile.getTotalInvestments(),
                profile.getCalculatedScore(),
                profile.getLastAssessmentAt(),
                profile.getCreatedAt()
        );
    }
}
