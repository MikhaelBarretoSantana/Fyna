package com.fyna.Fyna.core.features.users.data.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.UserPreferences;

@Repository
public interface UserPreferencesRepository extends JpaRepository<UserPreferences, UUID> {

    Optional<UserPreferences> findByUserId(UUID userId);

    boolean existsByUserId(UUID userId);
}
