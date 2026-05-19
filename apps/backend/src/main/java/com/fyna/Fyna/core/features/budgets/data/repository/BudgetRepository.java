package com.fyna.Fyna.core.features.budgets.data.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.Budget;

@Repository
public interface BudgetRepository extends JpaRepository<Budget, UUID> {

    List<Budget> findByUserIdAndIsActiveTrue(UUID userId);

    long countByCategoryIdAndIsActiveTrue(UUID categoryId);

    List<Budget> findByUserId(UUID userId);

    Optional<Budget> findByIdAndUserId(UUID id, UUID userId);

    @Query("SELECT b FROM Budget b WHERE b.user.id = :userId AND b.isActive = true " +
            "AND b.startDate <= :date AND b.endDate >= :date")
    List<Budget> findActiveBudgetsForDate(@Param("userId") UUID userId, @Param("date") LocalDate date);

    @Query("SELECT b FROM Budget b WHERE b.user.id = :userId AND b.category.id = :categoryId " +
            "AND b.isActive = true AND b.startDate <= :date AND b.endDate >= :date")
    List<Budget> findActiveBudgetsByCategoryForDate(@Param("userId") UUID userId,
            @Param("categoryId") UUID categoryId, @Param("date") LocalDate date);

    /** Budgets globais (category IS NULL) — somam toda despesa paga do usuário no período. */
    @Query("SELECT b FROM Budget b WHERE b.user.id = :userId AND b.category IS NULL " +
            "AND b.isActive = true AND b.startDate <= :date AND b.endDate >= :date")
    List<Budget> findActiveGlobalBudgetsForDate(@Param("userId") UUID userId,
            @Param("date") LocalDate date);
}
