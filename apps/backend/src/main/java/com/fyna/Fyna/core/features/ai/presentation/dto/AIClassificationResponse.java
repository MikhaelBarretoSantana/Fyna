package com.fyna.Fyna.core.features.ai.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.AIClassifications;

public record AIClassificationResponse(
        UUID id,
        UUID transactionId,
        UUID suggestedCategoryId,
        String suggestedCategoryName,
        UUID confirmedCategoryId,
        String confirmedCategoryName,
        BigDecimal confidenceScore,
        String originalText,
        String modelVersion,
        boolean wasConfirmed,
        boolean wasCorrected,
        Instant classifiedAt,
        Instant confirmedAt
) {
    public static AIClassificationResponse from(AIClassifications classification) {
        return new AIClassificationResponse(
                classification.getId(),
                classification.getTransactions() != null ? classification.getTransactions().getId() : null,
                classification.getSuggestedCategory() != null ? classification.getSuggestedCategory().getId() : null,
                classification.getSuggestedCategory() != null ? classification.getSuggestedCategory().getName() : null,
                classification.getConfirmedCategory() != null ? classification.getConfirmedCategory().getId() : null,
                classification.getConfirmedCategory() != null ? classification.getConfirmedCategory().getName() : null,
                classification.getConfidenceScore(),
                classification.getOriginalText(),
                classification.getModelVersion(),
                classification.getWasConfirmed(),
                classification.getWasCorrected(),
                classification.getClassifiedAt(),
                classification.getConfirmedAt()
        );
    }
}
