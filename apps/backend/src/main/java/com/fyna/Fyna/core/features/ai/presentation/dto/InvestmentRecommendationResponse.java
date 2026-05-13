package com.fyna.Fyna.core.features.ai.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.InvestmentRecommendation;
import com.fyna.Fyna.core.shared.enums.InvestmentRecommendationType;

public record InvestmentRecommendationResponse(
        UUID id,
        InvestmentRecommendationType recommendationType,
        String title,
        String description,
        String allocationSuggestion,
        BigDecimal potentialReturn,
        BigDecimal riskLevel,
        boolean wasViewed,
        Boolean wasFollowed,
        String modelVersion,
        Instant generatedAt,
        Instant viewedAt
) {
    public static InvestmentRecommendationResponse from(InvestmentRecommendation rec) {
        return new InvestmentRecommendationResponse(
                rec.getId(),
                rec.getRecommendationType(),
                rec.getTitle(),
                rec.getDescription(),
                rec.getAllocationSuggestion(),
                rec.getPotentialReturn(),
                rec.getRiskLevel(),
                rec.getWasViewed(),
                rec.getWasFollowed(),
                rec.getModelVersion(),
                rec.getGeneratedAt(),
                rec.getViewedAt()
        );
    }
}
