package com.fyna.Fyna.core.features.transactions.presentation.resource;

import java.time.LocalDate;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.transactions.domain.service.TransactionService;
import com.fyna.Fyna.core.features.transactions.presentation.dto.CreateTransactionRequest;
import com.fyna.Fyna.core.features.transactions.presentation.dto.TransactionResponse;
import com.fyna.Fyna.core.features.transactions.presentation.dto.UpdateTransactionRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;
import com.fyna.Fyna.core.shared.dto.PageResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionResource {

    private final TransactionService transactionService;
    private final SecurityUtils securityUtils;

    public TransactionResource(TransactionService transactionService, SecurityUtils securityUtils) {
        this.transactionService = transactionService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<TransactionResponse>>> getTransactions(
            @RequestParam(name = "startDate", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID accountId,
            @RequestParam(required = false) UUID categoryId,
            @PageableDefault(size = 20, sort = "transactionDate", direction = Sort.Direction.DESC) Pageable pageable) {

        UUID userId = securityUtils.getCurrentUserId();
        PageResponse<TransactionResponse> response;

        if (accountId != null) {
            response = transactionService.getTransactionsByAccount(userId, accountId, pageable);
        } else if (categoryId != null) {
            response = transactionService.getTransactionsByCategory(userId, categoryId, pageable);
        } else if (startDate != null && endDate != null) {
            response = transactionService.getTransactionsByDateRange(userId, startDate, endDate, pageable);
        } else {
            response = transactionService.getTransactions(userId, pageable);
        }

        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<TransactionResponse>> getTransaction(@PathVariable UUID id) {
        TransactionResponse transaction = transactionService.getTransaction(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(transaction));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TransactionResponse>> createTransaction(
            @Valid @RequestBody CreateTransactionRequest request) {
        TransactionResponse transaction = transactionService.createTransaction(
                securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(transaction));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<TransactionResponse>> updateTransaction(@PathVariable UUID id,
            @Valid @RequestBody UpdateTransactionRequest request) {
        TransactionResponse transaction = transactionService.updateTransaction(
                id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(transaction));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(@PathVariable UUID id) {
        transactionService.deleteTransaction(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
