package com.fyna.Fyna.core.features.recurring.domain.service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.features.recurring.data.repository.RecurringTransactionRepository;
import com.fyna.Fyna.core.features.recurring.presentation.dto.CreateRecurringTransactionRequest;
import com.fyna.Fyna.core.features.recurring.presentation.dto.RecurringTransactionResponse;
import com.fyna.Fyna.core.features.recurring.presentation.dto.UpdateRecurringTransactionRequest;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.RecurringTransactions;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.NotificationType;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsFrequencyTypes;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@Service
public class RecurringTransactionService {

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public RecurringTransactionService(RecurringTransactionRepository recurringTransactionRepository,
            TransactionRepository transactionRepository, AccountRepository accountRepository,
            CategoryRepository categoryRepository, UserRepository userRepository,
            NotificationService notificationService) {
        this.recurringTransactionRepository = recurringTransactionRepository;
        this.transactionRepository = transactionRepository;
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<RecurringTransactionResponse> getActiveRecurringTransactions(UUID userId) {
        return recurringTransactionRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(RecurringTransactionResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<RecurringTransactionResponse> getAllRecurringTransactions(UUID userId) {
        return recurringTransactionRepository.findByUserId(userId).stream()
                .map(RecurringTransactionResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public RecurringTransactionResponse getRecurringTransaction(UUID id, UUID userId) {
        RecurringTransactions rt = recurringTransactionRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("RecurringTransaction", "id", id));
        return RecurringTransactionResponse.from(rt);
    }

    @Transactional
    public RecurringTransactionResponse createRecurringTransaction(UUID userId, CreateRecurringTransactionRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Accounts account = accountRepository.findByIdAndUserId(request.accountId(), userId)
                .orElseThrow(() -> new ResourceNotFoundException("Account", "id", request.accountId()));

        RecurringTransactions rt = new RecurringTransactions();
        rt.setUser(user);
        rt.setAccount(account);
        rt.setType(com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes.valueOf(request.type().name()));
        rt.setAmount(request.amount());
        rt.setDescription(request.description());
        rt.setFrequency(request.frequency());
        rt.setFrequencyInterval(request.frequencyInterval() != null ? request.frequencyInterval() : 1);
        rt.setStartDate(request.startDate());
        rt.setEndDate(request.endDate());
        rt.setNextOccurrence(request.startDate());
        rt.setIsActive(true);

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            rt.setCategories(category);
        }

        rt = recurringTransactionRepository.save(rt);
        return RecurringTransactionResponse.from(rt);
    }

    @Transactional
    public RecurringTransactionResponse updateRecurringTransaction(UUID id, UUID userId,
            UpdateRecurringTransactionRequest request) {
        RecurringTransactions rt = recurringTransactionRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("RecurringTransaction", "id", id));

        if (request.amount() != null) rt.setAmount(request.amount());
        if (request.description() != null) rt.setDescription(request.description());
        if (request.endDate() != null) rt.setEndDate(request.endDate());
        if (request.isActive() != null) rt.setIsActive(request.isActive());

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            rt.setCategories(category);
        }

        rt = recurringTransactionRepository.save(rt);
        return RecurringTransactionResponse.from(rt);
    }

    @Transactional
    public void deleteRecurringTransaction(UUID id, UUID userId) {
        RecurringTransactions rt = recurringTransactionRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("RecurringTransaction", "id", id));
        rt.setIsActive(false);
        recurringTransactionRepository.save(rt);
    }

    /**
     * Processa transações recorrentes pendentes até a data atual.
     * Este método pode ser chamado por um scheduler.
     */
    @Transactional
    public void processRecurringTransactions() {
        LocalDate today = LocalDate.now();
        List<RecurringTransactions> pending = recurringTransactionRepository
                .findByIsActiveTrueAndNextOccurrenceLessThanEqual(today);

        for (RecurringTransactions rt : pending) {
            while (!rt.getNextOccurrence().isAfter(today)) {
                if (rt.getEndDate() != null && rt.getNextOccurrence().isAfter(rt.getEndDate())) {
                    rt.setIsActive(false);
                    break;
                }

                Transactions transaction = new Transactions();
                transaction.setUser(rt.getUser());
                transaction.setAccount(rt.getAccount());
                transaction.setCategories(rt.getCategories());
                transaction.setType(TransactionsType.valueOf(rt.getType().name()));
                transaction.setAmount(rt.getAmount());
                transaction.setDescription(rt.getDescription());
                transaction.setTransactionDate(rt.getNextOccurrence());
                transaction.setIsPaid(true);
                transaction.setIsRecurring(true);
                transaction.setRecurringTransactions(rt);

                transaction = transactionRepository.save(transaction);

                String metadata = String.format(
                        "{\"recurringId\":\"%s\",\"transactionId\":\"%s\",\"amount\":\"%s\"}",
                        rt.getId(), transaction.getId(), rt.getAmount().toPlainString());
                notificationService.createNotification(
                        rt.getUser().getId(),
                        NotificationType.RECURRING_TRANSACTION,
                        "Transação recorrente gerada",
                        String.format("\"%s\" foi registrada automaticamente.", rt.getDescription()),
                        "/transactions/" + transaction.getId(),
                        metadata
                );

                rt.setLastGenerated(rt.getNextOccurrence());
                rt.setNextOccurrence(calculateNextOccurrence(rt.getNextOccurrence(), rt.getFrequency(), rt.getFrequencyInterval()));
            }

            recurringTransactionRepository.save(rt);
        }
    }

    private LocalDate calculateNextOccurrence(LocalDate current, RecurringTransactionsFrequencyTypes frequency,
            int interval) {
        return switch (frequency) {
            case DAILY -> current.plusDays(interval);
            case WEEKLY -> current.plusWeeks(interval);
            case BIWEEKLY -> current.plusWeeks(2L * interval);
            case MONTHLY -> current.plusMonths(interval);
            case BIMONTHLY -> current.plusMonths(2L * interval);
            case QUARTERLY -> current.plusMonths(3L * interval);
            case SEMIANNUALLY -> current.plusMonths(6L * interval);
            case ANNUALLY -> current.plusYears(interval);
        };
    }
}
