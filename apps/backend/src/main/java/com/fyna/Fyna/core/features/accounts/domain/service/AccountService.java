package com.fyna.Fyna.core.features.accounts.domain.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.accounts.presentation.dto.AccountResponse;
import com.fyna.Fyna.core.features.accounts.presentation.dto.CreateAccountRequest;
import com.fyna.Fyna.core.features.accounts.presentation.dto.UpdateAccountRequest;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.User;

@Service
public class AccountService {

    private final AccountRepository accountRepository;
    private final UserRepository userRepository;

    public AccountService(AccountRepository accountRepository, UserRepository userRepository) {
        this.accountRepository = accountRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getAllAccounts(UUID userId) {
        return accountRepository.findByUserId(userId).stream()
                .map(AccountResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getActiveAccounts(UUID userId) {
        return accountRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(AccountResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AccountResponse getAccount(UUID accountId, UUID userId) {
        Accounts account = accountRepository.findByIdAndUserId(accountId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", accountId));
        return AccountResponse.from(account);
    }

    @Transactional
    public AccountResponse createAccount(UUID userId, CreateAccountRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Accounts account = new Accounts();
        account.setUser(user);
        account.setName(request.name());
        account.setType(request.type());
        account.setInstitution(request.institution());
        account.setColor(request.color());
        account.setIcon(request.icon());

        BigDecimal initialBalance = request.initialBalance() != null ? request.initialBalance() : BigDecimal.ZERO;
        account.setInitialBalance(initialBalance);
        account.setCurrentBalance(initialBalance);
        account.setIsActive(true);
        account.setIncludeInTotal(request.includeInTotal() != null ? request.includeInTotal() : true);

        account = accountRepository.save(account);
        return AccountResponse.from(account);
    }

    @Transactional
    public AccountResponse updateAccount(UUID accountId, UUID userId, UpdateAccountRequest request) {
        Accounts account = accountRepository.findByIdAndUserId(accountId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", accountId));

        if (request.name() != null) account.setName(request.name());
        if (request.type() != null) account.setType(request.type());
        if (request.institution() != null) account.setInstitution(request.institution());
        if (request.color() != null) account.setColor(request.color());
        if (request.icon() != null) account.setIcon(request.icon());
        if (request.currentBalance() != null) account.setCurrentBalance(request.currentBalance());
        if (request.isActive() != null) account.setIsActive(request.isActive());
        if (request.includeInTotal() != null) account.setIncludeInTotal(request.includeInTotal());

        account = accountRepository.save(account);
        return AccountResponse.from(account);
    }

    @Transactional
    public void deleteAccount(UUID accountId, UUID userId) {
        Accounts account = accountRepository.findByIdAndUserId(accountId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", accountId));
        account.setIsActive(false);
        accountRepository.save(account);
    }
}
