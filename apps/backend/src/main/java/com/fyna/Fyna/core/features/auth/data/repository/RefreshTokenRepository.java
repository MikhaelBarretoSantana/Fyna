package com.fyna.Fyna.core.features.auth.data.repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.RefreshTokens;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshTokens, UUID> {

    Optional<RefreshTokens> findByTokenHashAndIsRevokedFalse(String tokenHash);

    List<RefreshTokens> findByUserIdAndIsRevokedFalse(UUID userId);

    @Modifying
    @Query("UPDATE RefreshTokens r SET r.isRevoked = true, r.revokedAt = :now WHERE r.user.id = :userId AND r.isRevoked = false")
    void revokeAllByUserId(@Param("userId") UUID userId, @Param("now") Instant now);

    @Modifying
    @Query("DELETE FROM RefreshTokens r WHERE r.expiresAt < :now")
    void deleteAllExpired(@Param("now") Instant now);
}
