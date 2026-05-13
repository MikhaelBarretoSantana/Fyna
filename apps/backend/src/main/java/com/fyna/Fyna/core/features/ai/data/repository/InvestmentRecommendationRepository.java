package com.fyna.Fyna.core.features.ai.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.InvestmentRecommendation;
import com.fyna.Fyna.core.shared.enums.InvestmentRecommendationType;

@Repository
public interface InvestmentRecommendationRepository extends JpaRepository<InvestmentRecommendation, UUID> {

    Page<InvestmentRecommendation> findByUserIdOrderByGeneratedAtDesc(UUID userId, Pageable pageable);

    List<InvestmentRecommendation> findByUserIdAndWasViewedFalseOrderByGeneratedAtDesc(UUID userId);

    Optional<InvestmentRecommendation> findByIdAndUserId(UUID id, UUID userId);

    List<InvestmentRecommendation> findByUserIdAndRecommendationTypeOrderByGeneratedAtDesc(
            UUID userId, InvestmentRecommendationType type);

    long countByUserIdAndWasViewedFalse(UUID userId);
}
