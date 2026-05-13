package com.fyna.Fyna.core.features.risk.data.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.RiskProfile;

@Repository
public interface RiskProfileRepository extends JpaRepository<RiskProfile, UUID> {

    Optional<RiskProfile> findByUserId(UUID userId);

    boolean existsByUserId(UUID userId);
}
