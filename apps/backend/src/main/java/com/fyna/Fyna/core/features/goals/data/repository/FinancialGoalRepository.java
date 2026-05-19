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

    List<FinancialGoal> findByUserIdAndIsActiveTrue(UUID userId);

    List<FinancialGoal> findByUserIdAndStatusAndIsActiveTrue(UUID userId, FinancialGoalStatus status);

    Optional<FinancialGoal> findByIdAndUserIdAndIsActiveTrue(UUID id, UUID userId);

    /** Usado quando precisamos do registro mesmo após soft-delete (auditoria). */
    Optional<FinancialGoal> findByIdAndUserId(UUID id, UUID userId);

    long countByUserIdAndStatusAndIsActiveTrue(UUID userId, FinancialGoalStatus status);
}
