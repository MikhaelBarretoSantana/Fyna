package com.fyna.Fyna.core.features.risk.presentation.resource;

import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.risk.domain.service.RiskProfileService;
import com.fyna.Fyna.core.features.risk.presentation.dto.CreateRiskProfileRequest;
import com.fyna.Fyna.core.features.risk.presentation.dto.RiskProfileResponse;
import com.fyna.Fyna.core.features.risk.presentation.dto.UpdateRiskProfileRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/risk-profile")
public class RiskProfileResource {

    private final RiskProfileService riskProfileService;
    private final SecurityUtils securityUtils;

    public RiskProfileResource(RiskProfileService riskProfileService, SecurityUtils securityUtils) {
        this.riskProfileService = riskProfileService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<RiskProfileResponse>> getRiskProfile() {
        RiskProfileResponse response = riskProfileService.getRiskProfile(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RiskProfileResponse>> createRiskProfile(
            @Valid @RequestBody CreateRiskProfileRequest request) {
        RiskProfileResponse response = riskProfileService.createRiskProfile(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @PutMapping
    public ResponseEntity<ApiResponse<RiskProfileResponse>> updateRiskProfile(
            @Valid @RequestBody UpdateRiskProfileRequest request) {
        RiskProfileResponse response = riskProfileService.updateRiskProfile(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping
    public ResponseEntity<Void> deleteRiskProfile() {
        riskProfileService.deleteRiskProfile(securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
