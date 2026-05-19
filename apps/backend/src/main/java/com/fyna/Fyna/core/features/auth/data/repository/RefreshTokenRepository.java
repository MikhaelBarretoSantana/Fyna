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

    Optional<RefreshTokens> findByTokenHash(String tokenHash);

    List<RefreshTokens> findByUserIdAndIsRevokedFalse(UUID userId);

    /**
     * Revoga atomicamente um token específico apenas se ainda não estava revogado.
     * Retorna 1 se a chamada conseguiu revogar, 0 se já estava revogado por outra
     * thread/processo — usado para detectar reuse e quebrar a race em refresh paralelo.
     */
    @Modifying
    @Query("UPDATE RefreshTokens r SET r.isRevoked = true, r.revokedAt = :now " +
            "WHERE r.tokenHash = :tokenHash AND r.isRevoked = false")
    int revokeIfActive(@Param("tokenHash") String tokenHash, @Param("now") Instant now);

    @Modifying
    @Query("UPDATE RefreshTokens r SET r.isRevoked = true, r.revokedAt = :now WHERE r.user.id = :userId AND r.isRevoked = false")
    void revokeAllByUserId(@Param("userId") UUID userId, @Param("now") Instant now);

    @Modifying
    @Query("DELETE FROM RefreshTokens r WHERE r.expiresAt < :now")
    void deleteAllExpired(@Param("now") Instant now);
}
