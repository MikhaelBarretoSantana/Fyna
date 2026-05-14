package com.fyna.Fyna.core.features.notifications.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.FcmToken;

@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, UUID> {

    Optional<FcmToken> findByToken(String token);

    List<FcmToken> findByUserId(UUID userId);

    @Modifying
    @Query("DELETE FROM FcmToken t WHERE t.token = :token")
    int deleteByToken(@Param("token") String token);
}
