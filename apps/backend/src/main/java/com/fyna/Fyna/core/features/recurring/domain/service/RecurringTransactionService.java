package com.fyna.Fyna.core.features.recurring.domain.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
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

    private static final Logger log = LoggerFactory.getLogger(RecurringTransactionService.class);

    /** Cap de segurança para gerar transações em batch quando uma recorrente está muito atrasada. */
    private static final int MAX_OCCURRENCES_PER_RUN = 60;

    private final RecurringTransactionRepository recurringTransactionRepository;
    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final BudgetService budgetService;

    public RecurringTransactionService(RecurringTransactionRepository recurringTransactionRepository,
            TransactionRepository transactionRepository, AccountRepository accountRepository,
            CategoryRepository categoryRepository, UserRepository userRepository,
            NotificationService notificationService, BudgetService budgetService) {
        this.recurringTransactionRepository = recurringTransactionRepository;
        this.transactionRepository = transactionRepository;
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
        this.budgetService = budgetService;
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

        com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes rtType =
                com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes.valueOf(request.type().name());

        Accounts transferAccount = null;
        if (rtType == com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes.TRANSFER) {
            if (request.transferAccountId() == null) {
                throw new BadRequestException("transferAccountId é obrigatório para recorrentes do tipo TRANSFER");
            }
            if (request.transferAccountId().equals(request.accountId())) {
                throw new BadRequestException("Conta origem e destino devem ser diferentes");
            }
            transferAccount = accountRepository.findByIdAndUserId(request.transferAccountId(), userId)
                    .orElseThrow(() -> new ResourceNotFoundException("Account", "id", request.transferAccountId()));
        }

        RecurringTransactions rt = new RecurringTransactions();
        rt.setUser(user);
        rt.setAccount(account);
        rt.setTransferAccount(transferAccount);
        rt.setType(rtType);
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
     *
     * <p>Para cada ocorrência gerada:
     * <ul>
     *   <li>Cria a transação com {@code isPaid=true}.</li>
     *   <li>Atualiza o saldo da conta (e da conta destino, em TRANSFER).</li>
     *   <li>Atualiza o consumo de orçamento da categoria, se for EXPENSE.</li>
     * </ul>
     *
     * <p>Limita {@link #MAX_OCCURRENCES_PER_RUN} ocorrências por recorrente em uma única execução,
     * para evitar explosões quando uma recorrente está parada há meses/anos.
     * Este método pode ser chamado por um scheduler.
     */
    @Transactional
    public void processRecurringTransactions() {
        LocalDate today = LocalDate.now();
        List<RecurringTransactions> pending = recurringTransactionRepository
                .findByIsActiveTrueAndNextOccurrenceLessThanEqual(today);

        for (RecurringTransactions rt : pending) {
            int generated = 0;
            while (!rt.getNextOccurrence().isAfter(today)) {
                if (rt.getEndDate() != null && rt.getNextOccurrence().isAfter(rt.getEndDate())) {
                    rt.setIsActive(false);
                    break;
                }
                if (generated >= MAX_OCCURRENCES_PER_RUN) {
                    log.warn("Recorrente {} parou de gerar em {} (limite de {} por execução atingido)",
                            rt.getId(), rt.getNextOccurrence(), MAX_OCCURRENCES_PER_RUN);
                    break;
                }

                Transactions transaction = generateOneOccurrence(rt);
                generated++;

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

    /**
     * Cria a transação principal, espelho (se TRANSFER) e propaga efeitos em saldo + budget.
     * Mantém todo o lifecycle dentro de uma única transação ACID com a chamada externa.
     */
    private Transactions generateOneOccurrence(RecurringTransactions rt) {
        TransactionsType type = TransactionsType.valueOf(rt.getType().name());
        BigDecimal amount = rt.getAmount();
        LocalDate occurrenceDate = rt.getNextOccurrence();

        Transactions transaction = new Transactions();
        transaction.setUser(rt.getUser());
        transaction.setAccount(rt.getAccount());
        transaction.setCategories(rt.getCategories());
        transaction.setType(type);
        transaction.setAmount(amount);
        transaction.setDescription(rt.getDescription());
        transaction.setTransactionDate(occurrenceDate);
        transaction.setIsPaid(true);
        transaction.setIsRecurring(true);
        transaction.setRecurringTransactions(rt);

        transaction = transactionRepository.save(transaction);

        // Atualiza saldo da conta de origem
        applyBalance(transaction.getAccount(), type, amount);

        // TRANSFER: criar par no destino e debitar/creditar saldos corretamente
        if (type == TransactionsType.TRANSFER) {
            if (rt.getTransferAccount() == null) {
                // Recorrente legado, sem destino configurado — registra warning e segue
                // apenas com a perna origem (estado equivalente ao comportamento anterior).
                log.warn("Recorrente {} é TRANSFER sem transfer_account_id; tx {} ficou unilateral",
                        rt.getId(), transaction.getId());
            } else {
                Accounts destination = rt.getTransferAccount();
                Transactions pair = new Transactions();
                pair.setUser(rt.getUser());
                pair.setAccount(destination);
                pair.setCategories(rt.getCategories());
                pair.setType(TransactionsType.TRANSFER);
                pair.setAmount(amount);
                pair.setDescription(rt.getDescription());
                pair.setTransactionDate(occurrenceDate);
                pair.setIsPaid(true);
                pair.setIsRecurring(true);
                pair.setRecurringTransactions(rt);
                pair.setTransactions(transaction);
                pair = transactionRepository.save(pair);

                // Liga a transação origem ao par (relação bidirecional)
                transaction.setTransactions(pair);
                transaction = transactionRepository.save(transaction);

                // Credita o destino — applyBalance(TRANSFER) debita, então aplicamos diretamente
                destination.setCurrentBalance(destination.getCurrentBalance().add(amount));
                accountRepository.save(destination);
            }
        }

        // Atualiza consumo de orçamento (somente EXPENSE com categoria)
        if (type == TransactionsType.EXPENSE && rt.getCategories() != null) {
            try {
                budgetService.applyTransactionDelta(
                        rt.getUser().getId(),
                        rt.getCategories().getId(),
                        amount,
                        occurrenceDate);
            } catch (Exception e) {
                log.warn("Falha ao atualizar orçamento na recorrência {}: {}", rt.getId(), e.getMessage());
            }
        }

        return transaction;
    }

    private void applyBalance(Accounts account, TransactionsType type, BigDecimal amount) {
        BigDecimal current = account.getCurrentBalance();
        if (type == TransactionsType.INCOME) {
            account.setCurrentBalance(current.add(amount));
        } else if (type == TransactionsType.EXPENSE || type == TransactionsType.TRANSFER) {
            // TRANSFER aqui: trata só a perna de saída (limitação documentada acima).
            account.setCurrentBalance(current.subtract(amount));
        }
        accountRepository.save(account);
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
