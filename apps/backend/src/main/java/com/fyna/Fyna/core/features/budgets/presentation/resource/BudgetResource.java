package com.fyna.Fyna.core.features.budgets.presentation.resource;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
import com.fyna.Fyna.core.features.budgets.presentation.dto.BudgetResponse;
import com.fyna.Fyna.core.features.budgets.presentation.dto.CreateBudgetRequest;
import com.fyna.Fyna.core.features.budgets.presentation.dto.UpdateBudgetRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/budgets")
public class BudgetResource {

    private final BudgetService budgetService;
    private final SecurityUtils securityUtils;

    public BudgetResource(BudgetService budgetService, SecurityUtils securityUtils) {
        this.budgetService = budgetService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<BudgetResponse>>> getActiveBudgets() {
        List<BudgetResponse> response = budgetService.getActiveBudgets(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/current")
    public ResponseEntity<ApiResponse<List<BudgetResponse>>> getCurrentBudgets() {
        List<BudgetResponse> response = budgetService.getCurrentBudgets(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BudgetResponse>> getBudget(@PathVariable UUID id) {
        BudgetResponse response = budgetService.getBudget(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BudgetResponse>> createBudget(
            @Valid @RequestBody CreateBudgetRequest request) {
        BudgetResponse response = budgetService.createBudget(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BudgetResponse>> updateBudget(
            @PathVariable UUID id, @Valid @RequestBody UpdateBudgetRequest request) {
        BudgetResponse response = budgetService.updateBudget(id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteBudget(@PathVariable UUID id) {
        budgetService.deleteBudget(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
