package com.fyna.Fyna.core.features.ai.data.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.SpendingPrediction;

@Repository
public interface SpendingPredictionRepository extends JpaRepository<SpendingPrediction, UUID> {

    List<SpendingPrediction> findByUserIdOrderByPredictionDateDesc(UUID userId);

    @Query("SELECT sp FROM SpendingPrediction sp WHERE sp.user.id = :userId " +
            "AND sp.predictionDate BETWEEN :startDate AND :endDate " +
            "ORDER BY sp.predictionDate ASC")
    List<SpendingPrediction> findByUserIdAndDateRange(@Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    List<SpendingPrediction> findByUserIdAndCategoryIdOrderByPredictionDateDesc(UUID userId, UUID categoryId);

    @Query("SELECT sp FROM SpendingPrediction sp WHERE sp.user.id = :userId " +
            "AND sp.predictionDate = :date")
    List<SpendingPrediction> findByUserIdAndDate(@Param("userId") UUID userId, @Param("date") LocalDate date);
}
