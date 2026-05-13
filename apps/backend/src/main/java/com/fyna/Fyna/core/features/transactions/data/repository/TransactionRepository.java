package com.fyna.Fyna.core.features.transactions.data.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@Repository
public interface TransactionRepository extends JpaRepository<Transactions, UUID> {

    Page<Transactions> findByUserId(UUID userId, Pageable pageable);

    Optional<Transactions> findByIdAndUserId(UUID id, UUID userId);

    Page<Transactions> findByUserIdAndTransactionDateBetween(UUID userId, LocalDate startDate, LocalDate endDate, Pageable pageable);

    Page<Transactions> findByUserIdAndAccountId(UUID userId, UUID accountId, Pageable pageable);

    Page<Transactions> findByUserIdAndCategoriesId(UUID userId, UUID categoryId, Pageable pageable);

    Page<Transactions> findByUserIdAndType(UUID userId, TransactionsType type, Pageable pageable);

    List<Transactions> findByUserIdAndIsPaidFalseAndDueDateBefore(UUID userId, LocalDate date);

    @Query("SELECT COALESCE(SUM(t.amount), 0) FROM Transactions t WHERE t.user.id = :userId AND t.type = :type AND t.transactionDate BETWEEN :startDate AND :endDate")
    java.math.BigDecimal sumByUserIdAndTypeAndDateBetween(
            @Param("userId") UUID userId,
            @Param("type") TransactionsType type,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);

    @Query("SELECT t FROM Transactions t WHERE t.user.id = :userId AND t.transactionDate BETWEEN :startDate AND :endDate ORDER BY t.transactionDate DESC")
    List<Transactions> findByUserIdAndDateRange(
            @Param("userId") UUID userId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate);
}
