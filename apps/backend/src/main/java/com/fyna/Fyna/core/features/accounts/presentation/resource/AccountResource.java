package com.fyna.Fyna.core.features.accounts.presentation.resource;

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

import com.fyna.Fyna.core.features.accounts.domain.service.AccountService;
import com.fyna.Fyna.core.features.accounts.presentation.dto.AccountResponse;
import com.fyna.Fyna.core.features.accounts.presentation.dto.CreateAccountRequest;
import com.fyna.Fyna.core.features.accounts.presentation.dto.UpdateAccountRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/accounts")
public class AccountResource {

    private final AccountService accountService;
    private final SecurityUtils securityUtils;

    public AccountResource(AccountService accountService, SecurityUtils securityUtils) {
        this.accountService = accountService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AccountResponse>>> getAllAccounts() {
        List<AccountResponse> accounts = accountService.getActiveAccounts(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(accounts));
    }

    @GetMapping("/all")
    public ResponseEntity<ApiResponse<List<AccountResponse>>> getAllAccountsIncludingInactive() {
        List<AccountResponse> accounts = accountService.getAllAccounts(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(accounts));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountResponse>> getAccount(@PathVariable UUID id) {
        AccountResponse account = accountService.getAccount(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(account));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AccountResponse>> createAccount(@Valid @RequestBody CreateAccountRequest request) {
        AccountResponse account = accountService.createAccount(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(account));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountResponse>> updateAccount(@PathVariable UUID id,
            @Valid @RequestBody UpdateAccountRequest request) {
        AccountResponse account = accountService.updateAccount(id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(account));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAccount(@PathVariable UUID id) {
        accountService.deleteAccount(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
