package com.fyna.Fyna.core.features.recurring.data.repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.RecurringTransactions;

@Repository
public interface RecurringTransactionRepository extends JpaRepository<RecurringTransactions, UUID> {

    List<RecurringTransactions> findByUserIdAndIsActiveTrue(UUID userId);

    List<RecurringTransactions> findByUserId(UUID userId);

    Optional<RecurringTransactions> findByIdAndUserId(UUID id, UUID userId);

    List<RecurringTransactions> findByIsActiveTrueAndNextOccurrenceLessThanEqual(LocalDate date);

    List<RecurringTransactions> findByUserIdAndIsActiveTrueAndNextOccurrenceLessThanEqual(UUID userId, LocalDate date);
}
