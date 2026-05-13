package com.fyna.Fyna.core.features.ai.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.SpendingPrediction;

public record SpendingPredictionResponse(
        UUID id,
        UUID categoryId,
        String categoryName,
        LocalDate predictionDate,
        BigDecimal predictedAmount,
        BigDecimal actualAmount,
        BigDecimal confidenceLower,
        BigDecimal confidenceUpper,
        String modelVersion,
        Instant generatedAt
) {
    public static SpendingPredictionResponse from(SpendingPrediction prediction) {
        return new SpendingPredictionResponse(
                prediction.getId(),
                prediction.getCategory() != null ? prediction.getCategory().getId() : null,
                prediction.getCategory() != null ? prediction.getCategory().getName() : null,
                prediction.getPredictionDate(),
                prediction.getPredictedAmount(),
                prediction.getActualAmount(),
                prediction.getConfidenceLower(),
                prediction.getConfidenceUpper(),
                prediction.getModelVersion(),
                prediction.getGeneratedAt()
        );
    }
}
