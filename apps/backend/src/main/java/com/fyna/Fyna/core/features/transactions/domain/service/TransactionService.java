package com.fyna.Fyna.core.features.transactions.domain.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.ai.infrastructure.AIEngineClient;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.features.transactions.presentation.dto.CreateTransactionRequest;
import com.fyna.Fyna.core.features.transactions.presentation.dto.TransactionResponse;
import com.fyna.Fyna.core.features.transactions.presentation.dto.UpdateTransactionRequest;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.TransactionsType;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final AIEngineClient aiEngineClient;

    public TransactionService(TransactionRepository transactionRepository, AccountRepository accountRepository,
            CategoryRepository categoryRepository, UserRepository userRepository, AIEngineClient aiEngineClient) {
        this.transactionRepository = transactionRepository;
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.aiEngineClient = aiEngineClient;
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> getTransactions(UUID userId, Pageable pageable) {
        Page<TransactionResponse> page = transactionRepository.findByUserId(userId, pageable)
                .map(TransactionResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> getTransactionsByDateRange(UUID userId, LocalDate startDate,
            LocalDate endDate, Pageable pageable) {
        Page<TransactionResponse> page = transactionRepository
                .findByUserIdAndTransactionDateBetween(userId, startDate, endDate, pageable)
                .map(TransactionResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> getTransactionsByAccount(UUID userId, UUID accountId, Pageable pageable) {
        Page<TransactionResponse> page = transactionRepository.findByUserIdAndAccountId(userId, accountId, pageable)
                .map(TransactionResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public PageResponse<TransactionResponse> getTransactionsByCategory(UUID userId, UUID categoryId, Pageable pageable) {
        Page<TransactionResponse> page = transactionRepository.findByUserIdAndCategoriesId(userId, categoryId, pageable)
                .map(TransactionResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public TransactionResponse getTransaction(UUID transactionId, UUID userId) {
        Transactions transaction = transactionRepository.findByIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction", "id", transactionId));
        return TransactionResponse.from(transaction);
    }

    public TransactionResponse createTransaction(UUID userId, CreateTransactionRequest request) {
        // Persiste a transação e atualiza saldo dentro de uma única transação ACID
        Transactions transaction = persistTransaction(userId, request);

        // Chama a IA APÓS o commit — fora da transação para evitar rollback cruzado
        if (request.categoryId() == null) {
            aiEngineClient.classifyTransaction(
                    transaction.getId(),
                    userId,
                    request.description(),
                    request.amount(),
                    request.type().name()
            );
        }

        return TransactionResponse.from(transaction);
    }

    @Transactional
    protected Transactions persistTransaction(UUID userId, CreateTransactionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Accounts account = accountRepository.findByIdAndUserId(request.accountId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", request.accountId()));

        Transactions transaction = new Transactions();
        transaction.setUser(user);
        transaction.setAccount(account);
        transaction.setType(request.type());
        transaction.setAmount(request.amount());
        transaction.setDescription(request.description());
        transaction.setNotes(request.notes());
        transaction.setTransactionDate(request.transactionDate());
        transaction.setDueDate(request.dueDate());
        transaction.setIsPaid(request.isPaid() != null ? request.isPaid() : true);
        transaction.setIsRecurring(false);
        transaction.setAttachmentUrl(request.attachmentUrl());

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            transaction.setCategories(category);
        }

        transaction = transactionRepository.save(transaction);

        if (Boolean.TRUE.equals(transaction.getIsPaid())) {
            updateAccountBalance(account, request.type(), request.amount());
        }

        if (request.type() == TransactionsType.TRANSFER && request.transferAccountId() != null) {
            createTransferPair(user, transaction, request);
        }

        return transaction;
    }

    @Transactional
    public TransactionResponse updateTransaction(UUID transactionId, UUID userId, UpdateTransactionRequest request) {
        Transactions transaction = transactionRepository.findByIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction", "id", transactionId));

        if (request.description() != null) transaction.setDescription(request.description());
        if (request.notes() != null) transaction.setNotes(request.notes());
        if (request.transactionDate() != null) transaction.setTransactionDate(request.transactionDate());
        if (request.dueDate() != null) transaction.setDueDate(request.dueDate());
        if (request.attachmentUrl() != null) transaction.setAttachmentUrl(request.attachmentUrl());

        if (request.amount() != null) {
            // Reverter saldo antigo e aplicar novo
            if (Boolean.TRUE.equals(transaction.getIsPaid())) {
                reverseAccountBalance(transaction.getAccount(), transaction.getType(), transaction.getAmount());
                updateAccountBalance(transaction.getAccount(), transaction.getType(), request.amount());
            }
            transaction.setAmount(request.amount());
        }

        if (request.isPaid() != null && !request.isPaid().equals(transaction.getIsPaid())) {
            if (request.isPaid()) {
                updateAccountBalance(transaction.getAccount(), transaction.getType(), transaction.getAmount());
            } else {
                reverseAccountBalance(transaction.getAccount(), transaction.getType(), transaction.getAmount());
            }
            transaction.setIsPaid(request.isPaid());
        }

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            transaction.setCategories(category);
        }

        transaction = transactionRepository.save(transaction);
        return TransactionResponse.from(transaction);
    }

    @Transactional
    public void deleteTransaction(UUID transactionId, UUID userId) {
        Transactions transaction = transactionRepository.findByIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction", "id", transactionId));

        // Reverter saldo se paga
        if (Boolean.TRUE.equals(transaction.getIsPaid())) {
            reverseAccountBalance(transaction.getAccount(), transaction.getType(), transaction.getAmount());
        }

        transactionRepository.delete(transaction);
    }

    @Transactional(readOnly = true)
    public BigDecimal getSumByType(UUID userId, TransactionsType type, LocalDate startDate, LocalDate endDate) {
        return transactionRepository.sumByUserIdAndTypeAndDateBetween(userId, type, startDate, endDate);
    }

    private void updateAccountBalance(Accounts account, TransactionsType type, BigDecimal amount) {
        BigDecimal currentBalance = account.getCurrentBalance();
        if (type == TransactionsType.INCOME) {
            account.setCurrentBalance(currentBalance.add(amount));
        } else if (type == TransactionsType.EXPENSE) {
            account.setCurrentBalance(currentBalance.subtract(amount));
        }
        accountRepository.save(account);
    }

    private void reverseAccountBalance(Accounts account, TransactionsType type, BigDecimal amount) {
        BigDecimal currentBalance = account.getCurrentBalance();
        if (type == TransactionsType.INCOME) {
            account.setCurrentBalance(currentBalance.subtract(amount));
        } else if (type == TransactionsType.EXPENSE) {
            account.setCurrentBalance(currentBalance.add(amount));
        }
        accountRepository.save(account);
    }

    private void createTransferPair(User user, Transactions sourceTransaction, CreateTransactionRequest request) {
        Accounts targetAccount = accountRepository.findByIdAndUserId(request.transferAccountId(), user.getId())
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", request.transferAccountId()));

        Transactions pairTransaction = new Transactions();
        pairTransaction.setUser(user);
        pairTransaction.setAccount(targetAccount);
        pairTransaction.setType(TransactionsType.TRANSFER);
        pairTransaction.setAmount(request.amount());
        pairTransaction.setDescription(request.description());
        pairTransaction.setTransactionDate(request.transactionDate());
        pairTransaction.setIsPaid(request.isPaid() != null ? request.isPaid() : true);
        pairTransaction.setIsRecurring(false);
        pairTransaction.setTransactions(sourceTransaction);

        pairTransaction = transactionRepository.save(pairTransaction);

        sourceTransaction.setTransactions(pairTransaction);
        transactionRepository.save(sourceTransaction);

        // Atualizar saldos: saída da conta origem, entrada na conta destino
        if (Boolean.TRUE.equals(pairTransaction.getIsPaid())) {
            Accounts sourceAccount = sourceTransaction.getAccount();
            sourceAccount.setCurrentBalance(sourceAccount.getCurrentBalance().subtract(request.amount()));
            accountRepository.save(sourceAccount);

            targetAccount.setCurrentBalance(targetAccount.getCurrentBalance().add(request.amount()));
            accountRepository.save(targetAccount);
        }
    }
}
