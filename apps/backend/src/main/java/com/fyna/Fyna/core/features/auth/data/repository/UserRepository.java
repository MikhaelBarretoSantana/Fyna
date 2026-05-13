package com.fyna.Fyna.core.features.auth.data.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.UserStatus;

@Repository
public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByLogin(String login);

    Optional<User> findByEmail(String email);

    boolean existsByLogin(String login);

    boolean existsByEmail(String email);

    Optional<User> findByLoginAndStatus(String login, UserStatus status);
}
