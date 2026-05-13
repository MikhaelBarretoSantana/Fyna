package com.fyna.Fyna.core.features.users.domain.service;

import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.users.data.repository.UserPreferencesRepository;
import com.fyna.Fyna.core.features.users.presentation.dto.UpdateUserPreferencesRequest;
import com.fyna.Fyna.core.features.users.presentation.dto.UpdateUserRequest;
import com.fyna.Fyna.core.features.users.presentation.dto.UserPreferencesResponse;
import com.fyna.Fyna.core.features.users.presentation.dto.UserResponse;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.domain.UserPreferences;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final UserPreferencesRepository userPreferencesRepository;

    public UserService(UserRepository userRepository, UserPreferencesRepository userPreferencesRepository) {
        this.userRepository = userRepository;
        this.userPreferencesRepository = userPreferencesRepository;
    }

    @Transactional(readOnly = true)
    public UserResponse getProfile(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse updateProfile(UUID userId, UpdateUserRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        if (request.fullName() != null) {
            user.setFullName(request.fullName());
        }
        if (request.email() != null && !request.email().equals(user.getEmail())) {
            if (userRepository.existsByEmail(request.email())) {
                throw new BadRequestException("Email já está em uso");
            }
            user.setEmail(request.email());
            user.setEmailVerified(false);
        }
        if (request.phone() != null) {
            user.setPhone(request.phone());
        }
        if (request.avatarUrl() != null) {
            user.setAvatarUrl(request.avatarUrl());
        }
        if (request.birthDate() != null) {
            user.setBirthDate(request.birthDate());
        }

        user = userRepository.save(user);
        return UserResponse.from(user);
    }

    @Transactional(readOnly = true)
    public UserPreferencesResponse getPreferences(UUID userId) {
        UserPreferences prefs = userPreferencesRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("UserPreferences", "userId", userId));
        return UserPreferencesResponse.from(prefs);
    }

    @Transactional
    public UserPreferencesResponse updatePreferences(UUID userId, UpdateUserPreferencesRequest request) {
        UserPreferences prefs = userPreferencesRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("UserPreferences", "userId", userId));

        if (request.currency() != null) prefs.setCurrency(request.currency());
        if (request.locale() != null) prefs.setLocale(request.locale());
        if (request.timezone() != null) prefs.setTimeZone(request.timezone());
        if (request.theme() != null) prefs.setTheme(request.theme());
        if (request.pushNotifications() != null) prefs.setPushNotifications(request.pushNotifications());
        if (request.emailNotifications() != null) prefs.setEmailNotifications(request.emailNotifications());
        if (request.budgetAlerts() != null) prefs.setBudgetAlerts(request.budgetAlerts());
        if (request.weeklySummary() != null) prefs.setWeeklySummary(request.weeklySummary());
        if (request.aiSuggestions() != null) prefs.setAiSuggestions(request.aiSuggestions());
        if (request.firstDayOfWeek() != null) prefs.setFirstDayOfWeek(request.firstDayOfWeek());

        prefs = userPreferencesRepository.save(prefs);
        return UserPreferencesResponse.from(prefs);
    }
}
