package com.fyna.Fyna.core.features.goals.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.FinancialGoal;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

@Repository
public interface FinancialGoalRepository extends JpaRepository<FinancialGoal, UUID> {

    List<FinancialGoal> findByUserId(UUID userId);

    List<FinancialGoal> findByUserIdAndStatus(UUID userId, FinancialGoalStatus status);

    Optional<FinancialGoal> findByIdAndUserId(UUID id, UUID userId);

    long countByUserIdAndStatus(UUID userId, FinancialGoalStatus status);
}
