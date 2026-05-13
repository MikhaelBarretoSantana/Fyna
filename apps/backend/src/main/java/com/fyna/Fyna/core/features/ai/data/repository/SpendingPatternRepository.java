package com.fyna.Fyna.core.features.ai.data.repository;

import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.SpendingPattern;
import com.fyna.Fyna.core.shared.enums.SpendingPatternType;

@Repository
public interface SpendingPatternRepository extends JpaRepository<SpendingPattern, UUID> {

    List<SpendingPattern> findByUserIdAndIsActiveTrueOrderByDetectedAtDesc(UUID userId);

    List<SpendingPattern> findByUserIdOrderByDetectedAtDesc(UUID userId);

    List<SpendingPattern> findByUserIdAndPatternTypeAndIsActiveTrueOrderByDetectedAtDesc(
            UUID userId, SpendingPatternType patternType);
}
