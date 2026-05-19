package com.fyna.Fyna.core.features.transactions.domain.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.ai.infrastructure.AIEngineClient;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.features.transactions.presentation.dto.CreateTransactionRequest;
import com.fyna.Fyna.core.features.transactions.presentation.dto.TransactionResponse;
import com.fyna.Fyna.core.features.transactions.presentation.dto.UpdateTransactionRequest;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.NotificationType;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@Service
public class TransactionService {

    private static final Logger log = LoggerFactory.getLogger(TransactionService.class);

    /** Janela de histórico considerada para o cálculo de mediana/MAD da categoria. */
    private static final int ANOMALY_WINDOW_DAYS = 90;

    /** Mínimo de transações na janela para considerar o histórico estatisticamente útil. */
    private static final int ANOMALY_MIN_HISTORY = 5;

    /**
     * Limiar Z-robusto: anomalia quando |amount - mediana| / (1.4826 * MAD) >= 3.5.
     * MAD é resistente a outliers, ao contrário de média + desvio padrão.
     * 1.4826 converte MAD em estimador consistente do desvio padrão sob normalidade.
     */
    private static final double MAD_SCALE = 1.4826;
    private static final double ROBUST_Z_THRESHOLD = 3.5;

    /** Fallback quando todos os valores da janela são idênticos (MAD=0): usa múltiplo da mediana. */
    private static final BigDecimal FALLBACK_MULTIPLIER = new BigDecimal("2.0");

    private final TransactionRepository transactionRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;
    private final AIEngineClient aiEngineClient;
    private final BudgetService budgetService;
    private final NotificationService notificationService;

    public TransactionService(TransactionRepository transactionRepository, AccountRepository accountRepository,
            CategoryRepository categoryRepository, UserRepository userRepository, AIEngineClient aiEngineClient,
            BudgetService budgetService, NotificationService notificationService) {
        this.transactionRepository = transactionRepository;
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.aiEngineClient = aiEngineClient;
        this.budgetService = budgetService;
        this.notificationService = notificationService;
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

    @Transactional
    public TransactionResponse createTransaction(UUID userId, CreateTransactionRequest request) {
        // Validação de transferência: contas devem ser distintas
        if (request.type() == TransactionsType.TRANSFER
                && request.transferAccountId() != null
                && request.transferAccountId().equals(request.accountId())) {
            throw new BadRequestException("Conta origem e destino devem ser diferentes em uma transferência");
        }

        // Persiste a transação e atualiza saldo dentro de uma única transação ACID
        Transactions transaction = persistTransaction(userId, request);

        // Pós-processamento (fora da transação principal). Falhas aqui não devem
        // reverter o lançamento — só logamos e seguimos.
        if (request.type() == TransactionsType.EXPENSE
                && Boolean.TRUE.equals(transaction.getIsPaid())
                && request.categoryId() != null) {
            try {
                budgetService.applyTransactionDelta(userId, request.categoryId(),
                        request.amount(), request.transactionDate());
            } catch (Exception e) {
                log.warn("Falha ao atualizar consumo de orçamento para tx {}: {}",
                        transaction.getId(), e.getMessage());
            }
            try {
                maybeFireSpendingAnomaly(userId, transaction);
            } catch (Exception e) {
                log.warn("Falha ao avaliar anomalia para tx {}: {}",
                        transaction.getId(), e.getMessage());
            }
        }

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

    /**
     * Detecta gasto atípico usando estatísticas robustas: mediana + MAD
     * (Median Absolute Deviation) na janela de {@value #ANOMALY_WINDOW_DAYS} dias.
     *
     * <p>Algoritmo: Z-robusto = |amount - mediana| / (1.4826 * MAD). Dispara se Z >= 3.5.
     * Quando MAD é zero (todos os valores históricos idênticos), cai em fallback
     * {@code amount >= 2 * mediana} para não silenciar outliers em séries muito estáveis.
     *
     * <p>Vantagens vs média+desvio padrão:
     * <ul>
     *   <li>Não é arrastado por outliers passados (uma conta de R$10k não inflaciona o threshold).</li>
     *   <li>50% dos valores precisam ser anômalos para distorcer a mediana — muito mais robusto.</li>
     * </ul>
     */
    private void maybeFireSpendingAnomaly(UUID userId, Transactions tx) {
        if (tx.getCategories() == null) return;
        UUID categoryId = tx.getCategories().getId();
        LocalDate end = tx.getTransactionDate();
        LocalDate start = end.minusDays(ANOMALY_WINDOW_DAYS);

        List<BigDecimal> amounts = transactionRepository.findAmountsByUserCategoryType(
                userId, categoryId, TransactionsType.EXPENSE, start, end);
        if (amounts == null || amounts.size() < ANOMALY_MIN_HISTORY) return;

        // Cópia mutável para sorting
        List<BigDecimal> sorted = new ArrayList<>(amounts);
        sorted.sort(BigDecimal::compareTo);
        BigDecimal median = median(sorted);
        if (median.signum() <= 0) return;

        BigDecimal mad = medianAbsoluteDeviation(sorted, median);
        BigDecimal txAmount = tx.getAmount();
        BigDecimal deviation = txAmount.subtract(median).abs();

        boolean anomalous;
        if (mad.signum() == 0) {
            // Série constante: fallback ao múltiplo da mediana
            anomalous = txAmount.compareTo(median.multiply(FALLBACK_MULTIPLIER)) >= 0;
        } else {
            BigDecimal scaledMad = mad.multiply(BigDecimal.valueOf(MAD_SCALE));
            BigDecimal robustZ = deviation.divide(scaledMad, 4, RoundingMode.HALF_UP);
            anomalous = robustZ.compareTo(BigDecimal.valueOf(ROBUST_Z_THRESHOLD)) >= 0;
        }
        if (!anomalous) return;

        String categoryName = tx.getCategories().getName();
        String metadata = String.format(
                "{\"transactionId\":\"%s\",\"categoryId\":\"%s\",\"amount\":\"%s\",\"median\":\"%s\",\"mad\":\"%s\"}",
                tx.getId(), categoryId, txAmount.toPlainString(),
                median.toPlainString(), mad.toPlainString());
        notificationService.createNotification(
                userId,
                NotificationType.SPENDING_ANOMALY,
                "Gasto atípico detectado",
                String.format("Sua transação em \"%s\" está acima do padrão recente.", categoryName),
                "/transactions/" + tx.getId(),
                metadata
        );
    }

    /** Mediana de uma lista já ordenada (assume não vazia). */
    private static BigDecimal median(List<BigDecimal> sortedAsc) {
        int n = sortedAsc.size();
        int mid = n / 2;
        if (n % 2 == 1) return sortedAsc.get(mid);
        BigDecimal lower = sortedAsc.get(mid - 1);
        BigDecimal upper = sortedAsc.get(mid);
        return lower.add(upper).divide(BigDecimal.valueOf(2), 4, RoundingMode.HALF_UP);
    }

    /** MAD = mediana(|xi - mediana|). */
    private static BigDecimal medianAbsoluteDeviation(List<BigDecimal> sortedAsc, BigDecimal med) {
        List<BigDecimal> deviations = new ArrayList<>(sortedAsc.size());
        for (BigDecimal v : sortedAsc) {
            deviations.add(v.subtract(med).abs());
        }
        deviations.sort(BigDecimal::compareTo);
        return median(deviations);
    }

    private Transactions persistTransaction(UUID userId, CreateTransactionRequest request) {
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

        // Snapshot do estado antigo (necessário para reverter saldo/budget corretamente)
        BigDecimal oldAmount = transaction.getAmount();
        Boolean oldIsPaid = transaction.getIsPaid();
        LocalDate oldDate = transaction.getTransactionDate();
        UUID oldCategoryId = transaction.getCategories() != null ? transaction.getCategories().getId() : null;
        TransactionsType txType = transaction.getType();
        Transactions pair = transaction.getTransactions();

        if (request.description() != null) {
            transaction.setDescription(request.description());
            if (pair != null) pair.setDescription(request.description());
        }
        if (request.notes() != null) transaction.setNotes(request.notes());
        if (request.transactionDate() != null) {
            transaction.setTransactionDate(request.transactionDate());
            if (pair != null) pair.setTransactionDate(request.transactionDate());
        }
        if (request.dueDate() != null) transaction.setDueDate(request.dueDate());
        if (request.attachmentUrl() != null) transaction.setAttachmentUrl(request.attachmentUrl());

        BigDecimal newAmount = request.amount() != null ? request.amount() : oldAmount;
        Boolean newIsPaid = request.isPaid() != null ? request.isPaid() : oldIsPaid;

        boolean amountChanged = request.amount() != null && newAmount.compareTo(oldAmount) != 0;
        boolean paidChanged = request.isPaid() != null && !newIsPaid.equals(oldIsPaid);

        if (amountChanged || paidChanged) {
            // Reverte saldo antigo (se pago) — ambos os lados em TRANSFER
            if (Boolean.TRUE.equals(oldIsPaid)) {
                reverseAccountBalance(transaction.getAccount(), txType, oldAmount);
                if (txType == TransactionsType.TRANSFER && pair != null) {
                    // O par fez o movimento oposto (entrada na conta destino). Reverter:
                    pair.getAccount().setCurrentBalance(pair.getAccount().getCurrentBalance().subtract(oldAmount));
                    accountRepository.save(pair.getAccount());
                }
            }
            // Aplica saldo novo (se pago agora)
            if (Boolean.TRUE.equals(newIsPaid)) {
                updateAccountBalance(transaction.getAccount(), txType, newAmount);
                if (txType == TransactionsType.TRANSFER && pair != null) {
                    pair.getAccount().setCurrentBalance(pair.getAccount().getCurrentBalance().add(newAmount));
                    accountRepository.save(pair.getAccount());
                }
            }
            transaction.setAmount(newAmount);
            transaction.setIsPaid(newIsPaid);
            if (pair != null) {
                pair.setAmount(newAmount);
                pair.setIsPaid(newIsPaid);
                transactionRepository.save(pair);
            }
        }

        UUID newCategoryId = oldCategoryId;
        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            transaction.setCategories(category);
            newCategoryId = category.getId();
        }

        transaction = transactionRepository.save(transaction);

        // Reconcilia consumo de orçamento (somente EXPENSE)
        if (txType == TransactionsType.EXPENSE) {
            try {
                // Reverte o que a transação antiga contribuía (se contribuía)
                if (Boolean.TRUE.equals(oldIsPaid) && oldCategoryId != null) {
                    budgetService.applyTransactionDelta(userId, oldCategoryId, oldAmount.negate(), oldDate);
                }
                // Aplica o que a transação nova passa a contribuir
                if (Boolean.TRUE.equals(newIsPaid) && newCategoryId != null) {
                    budgetService.applyTransactionDelta(userId, newCategoryId, newAmount, transaction.getTransactionDate());
                }
            } catch (Exception e) {
                log.warn("Falha ao reconciliar orçamento na atualização da tx {}: {}",
                        transaction.getId(), e.getMessage());
            }

            // Reavalia anomalia se houve mudança relevante (valor, categoria ou virou pago)
            boolean categoryChanged = newCategoryId != null && !newCategoryId.equals(oldCategoryId);
            boolean becamePaid = Boolean.TRUE.equals(newIsPaid) && !Boolean.TRUE.equals(oldIsPaid);
            if (Boolean.TRUE.equals(newIsPaid) && (amountChanged || categoryChanged || becamePaid)) {
                try {
                    maybeFireSpendingAnomaly(userId, transaction);
                } catch (Exception e) {
                    log.warn("Falha ao avaliar anomalia na atualização da tx {}: {}",
                            transaction.getId(), e.getMessage());
                }
            }
        }

        return TransactionResponse.from(transaction);
    }

    @Transactional
    public void deleteTransaction(UUID transactionId, UUID userId) {
        Transactions transaction = transactionRepository.findByIdAndUserId(transactionId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction", "id", transactionId));

        Transactions pair = transaction.getTransactions();
        TransactionsType txType = transaction.getType();
        boolean isPaid = Boolean.TRUE.equals(transaction.getIsPaid());

        // Reverter saldo (ambos os lados em TRANSFER)
        if (isPaid) {
            reverseAccountBalance(transaction.getAccount(), txType, transaction.getAmount());
            if (txType == TransactionsType.TRANSFER && pair != null) {
                pair.getAccount().setCurrentBalance(pair.getAccount().getCurrentBalance().subtract(transaction.getAmount()));
                accountRepository.save(pair.getAccount());
            }
        }

        // Reverter consumo de orçamento
        if (txType == TransactionsType.EXPENSE && isPaid && transaction.getCategories() != null) {
            try {
                budgetService.applyTransactionDelta(userId,
                        transaction.getCategories().getId(),
                        transaction.getAmount().negate(),
                        transaction.getTransactionDate());
            } catch (Exception e) {
                log.warn("Falha ao reverter orçamento na exclusão da tx {}: {}",
                        transaction.getId(), e.getMessage());
            }
        }

        // Remover o par primeiro, quebrando o vínculo circular
        if (pair != null) {
            transaction.setTransactions(null);
            pair.setTransactions(null);
            transactionRepository.save(transaction);
            transactionRepository.save(pair);
            transactionRepository.delete(pair);
        }

        transactionRepository.delete(transaction);
    }

    @Transactional(readOnly = true)
    public BigDecimal getSumByType(UUID userId, TransactionsType type, LocalDate startDate, LocalDate endDate) {
        return transactionRepository.sumByUserIdAndTypeAndDateBetween(userId, type, startDate, endDate);
    }

    /**
     * Aplica o movimento da transação na conta passada.
     * Para TRANSFER, trata a {@code account} como conta de SAÍDA (origem da perna);
     * a contrapartida no destino é responsabilidade do chamador.
     */
    private void updateAccountBalance(Accounts account, TransactionsType type, BigDecimal amount) {
        BigDecimal currentBalance = account.getCurrentBalance();
        if (type == TransactionsType.INCOME) {
            account.setCurrentBalance(currentBalance.add(amount));
        } else if (type == TransactionsType.EXPENSE || type == TransactionsType.TRANSFER) {
            account.setCurrentBalance(currentBalance.subtract(amount));
        }
        accountRepository.save(account);
    }

    /** Inverso de {@link #updateAccountBalance}. Mesma convenção para TRANSFER. */
    private void reverseAccountBalance(Accounts account, TransactionsType type, BigDecimal amount) {
        BigDecimal currentBalance = account.getCurrentBalance();
        if (type == TransactionsType.INCOME) {
            account.setCurrentBalance(currentBalance.subtract(amount));
        } else if (type == TransactionsType.EXPENSE || type == TransactionsType.TRANSFER) {
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

        // Atualizar saldo do DESTINO. A perna de saída já foi tratada por
        // updateAccountBalance(source, TRANSFER, amount) em persistTransaction.
        if (Boolean.TRUE.equals(pairTransaction.getIsPaid())) {
            targetAccount.setCurrentBalance(targetAccount.getCurrentBalance().add(request.amount()));
            accountRepository.save(targetAccount);
        }
    }
}
