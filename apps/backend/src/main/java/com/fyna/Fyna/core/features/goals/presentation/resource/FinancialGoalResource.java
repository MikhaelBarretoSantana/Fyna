package com.fyna.Fyna.core.features.goals.presentation.resource;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.goals.domain.service.FinancialGoalService;
import com.fyna.Fyna.core.features.goals.presentation.dto.CreateFinancialGoalRequest;
import com.fyna.Fyna.core.features.goals.presentation.dto.FinancialGoalResponse;
import com.fyna.Fyna.core.features.goals.presentation.dto.UpdateFinancialGoalRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/goals")
public class FinancialGoalResource {

    private final FinancialGoalService financialGoalService;
    private final SecurityUtils securityUtils;

    public FinancialGoalResource(FinancialGoalService financialGoalService, SecurityUtils securityUtils) {
        this.financialGoalService = financialGoalService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<FinancialGoalResponse>>> getAllGoals(
            @RequestParam(required = false) FinancialGoalStatus status) {
        UUID userId = securityUtils.getCurrentUserId();
        List<FinancialGoalResponse> response = status != null
                ? financialGoalService.getGoalsByStatus(userId, status)
                : financialGoalService.getAllGoals(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<FinancialGoalResponse>> getGoal(@PathVariable UUID id) {
        FinancialGoalResponse response = financialGoalService.getGoal(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<FinancialGoalResponse>> createGoal(
            @Valid @RequestBody CreateFinancialGoalRequest request) {
        FinancialGoalResponse response = financialGoalService.createGoal(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<FinancialGoalResponse>> updateGoal(
            @PathVariable UUID id, @Valid @RequestBody UpdateFinancialGoalRequest request) {
        FinancialGoalResponse response =
                financialGoalService.updateGoal(id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/{id}/progress")
    public ResponseEntity<ApiResponse<FinancialGoalResponse>> addProgress(
            @PathVariable UUID id, @RequestParam BigDecimal amount) {
        FinancialGoalResponse response =
                financialGoalService.addProgress(id, securityUtils.getCurrentUserId(), amount);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteGoal(@PathVariable UUID id) {
        financialGoalService.deleteGoal(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
