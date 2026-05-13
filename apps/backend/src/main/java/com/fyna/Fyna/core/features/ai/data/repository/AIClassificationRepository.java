package com.fyna.Fyna.core.features.ai.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.AIClassifications;

@Repository
public interface AIClassificationRepository extends JpaRepository<AIClassifications, UUID> {

    Optional<AIClassifications> findByTransactionsId(UUID transactionId);

    List<AIClassifications> findByTransactionsUserIdOrderByClassifiedAtDesc(UUID userId);

    @Query("SELECT ac FROM AIClassifications ac WHERE ac.transactions.user.id = :userId " +
            "AND ac.wasConfirmed = false AND ac.wasCorrected = false ORDER BY ac.classifiedAt DESC")
    List<AIClassifications> findPendingClassifications(@Param("userId") UUID userId);

    long countByTransactionsUserIdAndWasConfirmedFalseAndWasCorrectedFalse(UUID userId);
}
