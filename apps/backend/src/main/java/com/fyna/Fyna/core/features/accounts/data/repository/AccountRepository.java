package com.fyna.Fyna.core.features.accounts.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.enums.AccountTypes;

@Repository
public interface AccountRepository extends JpaRepository<Accounts, UUID> {

    List<Accounts> findByUserIdAndIsActiveTrue(UUID userId);

    List<Accounts> findByUserId(UUID userId);

    Optional<Accounts> findByIdAndUserId(UUID id, UUID userId);

    List<Accounts> findByUserIdAndType(UUID userId, AccountTypes type);

    @Query("SELECT COALESCE(SUM(a.currentBalance), 0) FROM Accounts a WHERE a.user.id = :userId AND a.isActive = true AND a.includeInTotal = true")
    java.math.BigDecimal getTotalBalance(@Param("userId") UUID userId);
}
