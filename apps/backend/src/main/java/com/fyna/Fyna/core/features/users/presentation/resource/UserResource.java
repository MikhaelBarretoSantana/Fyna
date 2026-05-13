package com.fyna.Fyna.core.features.users.presentation.resource;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.users.domain.service.UserService;
import com.fyna.Fyna.core.features.users.presentation.dto.UpdateUserPreferencesRequest;
import com.fyna.Fyna.core.features.users.presentation.dto.UpdateUserRequest;
import com.fyna.Fyna.core.features.users.presentation.dto.UserPreferencesResponse;
import com.fyna.Fyna.core.features.users.presentation.dto.UserResponse;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/users")
public class UserResource {

    private final UserService userService;
    private final SecurityUtils securityUtils;

    public UserResource(UserService userService, SecurityUtils securityUtils) {
        this.userService = userService;
        this.securityUtils = securityUtils;
    }

    @GetMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> getProfile() {
        UserResponse response = userService.getProfile(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/me")
    public ResponseEntity<ApiResponse<UserResponse>> updateProfile(@Valid @RequestBody UpdateUserRequest request) {
        UserResponse response = userService.updateProfile(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/me/preferences")
    public ResponseEntity<ApiResponse<UserPreferencesResponse>> getPreferences() {
        UserPreferencesResponse response = userService.getPreferences(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PutMapping("/me/preferences")
    public ResponseEntity<ApiResponse<UserPreferencesResponse>> updatePreferences(
            @Valid @RequestBody UpdateUserPreferencesRequest request) {
        UserPreferencesResponse response = userService.updatePreferences(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }
}
