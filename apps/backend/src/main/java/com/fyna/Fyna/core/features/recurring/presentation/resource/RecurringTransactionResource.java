package com.fyna.Fyna.core.features.recurring.presentation.resource;

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

import com.fyna.Fyna.core.features.recurring.domain.service.RecurringTransactionService;
import com.fyna.Fyna.core.features.recurring.presentation.dto.CreateRecurringTransactionRequest;
import com.fyna.Fyna.core.features.recurring.presentation.dto.RecurringTransactionResponse;
import com.fyna.Fyna.core.features.recurring.presentation.dto.UpdateRecurringTransactionRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/recurring-transactions")
public class RecurringTransactionResource {

    private final RecurringTransactionService recurringTransactionService;
    private final SecurityUtils securityUtils;

    public RecurringTransactionResource(RecurringTransactionService recurringTransactionService,
            SecurityUtils securityUtils) {
        this.recurringTransactionService = recurringTransactionService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<RecurringTransactionResponse>>> getActiveRecurringTransactions() {
        List<RecurringTransactionResponse> response =
                recurringTransactionService.getActiveRecurringTransactions(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<RecurringTransactionResponse>>> getAllRecurringTransactions() {
        List<RecurringTransactionResponse> response =
                recurringTransactionService.getAllRecurringTransactions(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<RecurringTransactionResponse>> getRecurringTransaction(@PathVariable UUID id) {
        RecurringTransactionResponse response =
                recurringTransactionService.getRecurringTransaction(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<RecurringTransactionResponse>> createRecurringTransaction(
            @Valid @RequestBody CreateRecurringTransactionRequest request) {
        RecurringTransactionResponse response =
                recurringTransactionService.createRecurringTransaction(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(response));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<RecurringTransactionResponse>> updateRecurringTransaction(
            @PathVariable UUID id, @Valid @RequestBody UpdateRecurringTransactionRequest request) {
        RecurringTransactionResponse response =
                recurringTransactionService.updateRecurringTransaction(id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteRecurringTransaction(@PathVariable UUID id) {
        recurringTransactionService.deleteRecurringTransaction(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
