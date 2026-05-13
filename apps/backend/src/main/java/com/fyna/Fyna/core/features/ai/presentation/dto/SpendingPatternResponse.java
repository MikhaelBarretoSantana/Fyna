package com.fyna.Fyna.core.features.ai.presentation.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.SpendingPattern;
import com.fyna.Fyna.core.shared.enums.SpendingPatternType;

public record SpendingPatternResponse(
        UUID id,
        SpendingPatternType patternType,
        String description,
        String patternData,
        BigDecimal significanceScore,
        LocalDate detectedFrom,
        LocalDate detectedTo,
        boolean isActive,
        String modelVersion,
        Instant detectedAt
) {
    public static SpendingPatternResponse from(SpendingPattern pattern) {
        return new SpendingPatternResponse(
                pattern.getId(),
                pattern.getPatternType(),
                pattern.getDescription(),
                pattern.getPatternData(),
                pattern.getSignificanceScore(),
                pattern.getDetectedFrom(),
                pattern.getDetectedTo(),
                pattern.getIsActive(),
                pattern.getModelVersion(),
                pattern.getDetectedAt()
        );
    }
}
