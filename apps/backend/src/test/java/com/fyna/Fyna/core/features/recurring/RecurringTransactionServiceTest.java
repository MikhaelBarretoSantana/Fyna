package com.fyna.Fyna.core.features.recurring;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.features.recurring.data.repository.RecurringTransactionRepository;
import com.fyna.Fyna.core.features.recurring.domain.service.RecurringTransactionService;
import com.fyna.Fyna.core.features.recurring.presentation.dto.CreateRecurringTransactionRequest;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.RecurringTransactions;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsFrequencyTypes;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@ExtendWith(MockitoExtension.class)
class RecurringTransactionServiceTest {

    @Mock RecurringTransactionRepository recurringTransactionRepository;
    @Mock TransactionRepository transactionRepository;
    @Mock AccountRepository accountRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock UserRepository userRepository;
    @Mock NotificationService notificationService;
    @Mock BudgetService budgetService;

    @InjectMocks RecurringTransactionService service;

    private UUID userId;
    private User user;
    private Accounts source;
    private Accounts destination;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        user = new User();
        user.setId(userId);

        source = new Accounts();
        source.setId(UUID.randomUUID());
        source.setUser(user);
        source.setCurrentBalance(new BigDecimal("1000.00"));
        source.setIsActive(true);
        source.setIncludeInTotal(true);

        destination = new Accounts();
        destination.setId(UUID.randomUUID());
        destination.setUser(user);
        destination.setCurrentBalance(new BigDecimal("500.00"));
        destination.setIsActive(true);
        destination.setIncludeInTotal(true);
    }

    // ─── CREATE: validações de TRANSFER ───────────────────────────────────

    @Test
    void create_transferSemTransferAccountId_deveFalhar() {
        var request = new CreateRecurringTransactionRequest(
                source.getId(), null, null,
                RecurringTransactionsTypes.TRANSFER, new BigDecimal("100"),
                "Aporte mensal", RecurringTransactionsFrequencyTypes.MONTHLY, 1,
                LocalDate.now(), null
        );
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(accountRepository.findByIdAndUserId(source.getId(), userId)).thenReturn(Optional.of(source));

        assertThatThrownBy(() -> service.createRecurringTransaction(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("transferAccountId");
    }

    @Test
    void create_transferParaMesmaConta_deveFalhar() {
        var request = new CreateRecurringTransactionRequest(
                source.getId(), source.getId(), null,
                RecurringTransactionsTypes.TRANSFER, new BigDecimal("100"),
                "Transfer inválida", RecurringTransactionsFrequencyTypes.MONTHLY, 1,
                LocalDate.now(), null
        );
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(accountRepository.findByIdAndUserId(source.getId(), userId)).thenReturn(Optional.of(source));

        assertThatThrownBy(() -> service.createRecurringTransaction(userId, request))
                .isInstanceOf(BadRequestException.class)
                .hasMessageContaining("diferentes");
    }

    @Test
    void create_transferValido_persisteComTransferAccount() {
        var request = new CreateRecurringTransactionRequest(
                source.getId(), destination.getId(), null,
                RecurringTransactionsTypes.TRANSFER, new BigDecimal("100"),
                "Aporte mensal", RecurringTransactionsFrequencyTypes.MONTHLY, 1,
                LocalDate.now(), null
        );
        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(accountRepository.findByIdAndUserId(source.getId(), userId)).thenReturn(Optional.of(source));
        when(accountRepository.findByIdAndUserId(destination.getId(), userId)).thenReturn(Optional.of(destination));
        when(recurringTransactionRepository.save(any(RecurringTransactions.class)))
                .thenAnswer(inv -> {
                    RecurringTransactions rt = inv.getArgument(0);
                    rt.setId(UUID.randomUUID());
                    return rt;
                });

        service.createRecurringTransaction(userId, request);

        ArgumentCaptor<RecurringTransactions> captor = ArgumentCaptor.forClass(RecurringTransactions.class);
        verify(recurringTransactionRepository).save(captor.capture());
        assertThat(captor.getValue().getTransferAccount()).isEqualTo(destination);
        assertThat(captor.getValue().getType()).isEqualTo(RecurringTransactionsTypes.TRANSFER);
    }

    // ─── PROCESS: TRANSFER bilateral ───────────────────────────────────────

    @Test
    void process_transferRecorrente_creditaDestinoEDebitaOrigem() {
        RecurringTransactions rt = transferRecurringDue(new BigDecimal("100"));
        when(recurringTransactionRepository.findByIsActiveTrueAndNextOccurrenceLessThanEqual(any()))
                .thenReturn(List.of(rt));
        when(transactionRepository.save(any(Transactions.class)))
                .thenAnswer(inv -> {
                    Transactions tx = inv.getArgument(0);
                    if (tx.getId() == null) tx.setId(UUID.randomUUID());
                    return tx;
                });

        service.processRecurringTransactions();

        // Saldo origem: 1000 - 100 = 900
        assertThat(source.getCurrentBalance()).isEqualByComparingTo("900.00");
        // Saldo destino: 500 + 100 = 600
        assertThat(destination.getCurrentBalance()).isEqualByComparingTo("600.00");

        // Salvou origem (via applyBalance) e destino (crédito da transfer)
        verify(accountRepository, atLeastOnce()).save(source);
        verify(accountRepository, atLeastOnce()).save(destination);

        // Duas transações persistidas (uma para cada lado da TRANSFER) + 1 save para
        // religar a transação origem ao par = 3 saves de transaction
        verify(transactionRepository, times(3)).save(any(Transactions.class));
    }

    @Test
    void process_expenseRecorrente_aplicaBudgetDelta() {
        RecurringTransactions rt = expenseRecurringDue(new BigDecimal("80"));
        UUID categoryId = rt.getCategories().getId();
        LocalDate occurrence = rt.getNextOccurrence();

        when(recurringTransactionRepository.findByIsActiveTrueAndNextOccurrenceLessThanEqual(any()))
                .thenReturn(List.of(rt));
        when(transactionRepository.save(any(Transactions.class)))
                .thenAnswer(inv -> {
                    Transactions tx = inv.getArgument(0);
                    if (tx.getId() == null) tx.setId(UUID.randomUUID());
                    return tx;
                });

        service.processRecurringTransactions();

        assertThat(source.getCurrentBalance()).isEqualByComparingTo("920.00");
        verify(budgetService).applyTransactionDelta(eq(userId), eq(categoryId),
                eq(new BigDecimal("80")), eq(occurrence));
    }

    @Test
    void process_incomeRecorrente_naoTocaBudget() {
        RecurringTransactions rt = incomeRecurringDue(new BigDecimal("200"));
        when(recurringTransactionRepository.findByIsActiveTrueAndNextOccurrenceLessThanEqual(any()))
                .thenReturn(List.of(rt));
        when(transactionRepository.save(any(Transactions.class)))
                .thenAnswer(inv -> {
                    Transactions tx = inv.getArgument(0);
                    if (tx.getId() == null) tx.setId(UUID.randomUUID());
                    return tx;
                });

        service.processRecurringTransactions();

        assertThat(source.getCurrentBalance()).isEqualByComparingTo("1200.00");
        verify(budgetService, never()).applyTransactionDelta(any(), any(), any(), any());
    }

    @Test
    void process_transferRecorrenteLegadoSemTransferAccount_geraUnilateralEAvisa() {
        RecurringTransactions rt = transferRecurringDue(new BigDecimal("50"));
        rt.setTransferAccount(null); // legado anterior à V23
        when(recurringTransactionRepository.findByIsActiveTrueAndNextOccurrenceLessThanEqual(any()))
                .thenReturn(List.of(rt));
        when(transactionRepository.save(any(Transactions.class)))
                .thenAnswer(inv -> {
                    Transactions tx = inv.getArgument(0);
                    if (tx.getId() == null) tx.setId(UUID.randomUUID());
                    return tx;
                });

        service.processRecurringTransactions();

        // Apenas perna de saída foi aplicada
        assertThat(source.getCurrentBalance()).isEqualByComparingTo("950.00");
        // Destino não foi tocado
        assertThat(destination.getCurrentBalance()).isEqualByComparingTo("500.00");
        verify(accountRepository, never()).save(destination);
    }

    // ─── helpers ───────────────────────────────────────────────────────────

    private RecurringTransactions transferRecurringDue(BigDecimal amount) {
        RecurringTransactions rt = new RecurringTransactions();
        rt.setId(UUID.randomUUID());
        rt.setUser(user);
        rt.setAccount(source);
        rt.setTransferAccount(destination);
        rt.setType(RecurringTransactionsTypes.TRANSFER);
        rt.setAmount(amount);
        rt.setDescription("Aporte");
        rt.setFrequency(RecurringTransactionsFrequencyTypes.MONTHLY);
        rt.setFrequencyInterval(1);
        rt.setStartDate(LocalDate.now().minusDays(1));
        rt.setNextOccurrence(LocalDate.now());
        rt.setIsActive(true);
        return rt;
    }

    private RecurringTransactions expenseRecurringDue(BigDecimal amount) {
        RecurringTransactions rt = new RecurringTransactions();
        rt.setId(UUID.randomUUID());
        rt.setUser(user);
        rt.setAccount(source);
        rt.setType(RecurringTransactionsTypes.EXPENSE);
        rt.setAmount(amount);
        rt.setDescription("Internet");
        rt.setFrequency(RecurringTransactionsFrequencyTypes.MONTHLY);
        rt.setFrequencyInterval(1);
        rt.setStartDate(LocalDate.now().minusDays(1));
        rt.setNextOccurrence(LocalDate.now());
        rt.setIsActive(true);
        com.fyna.Fyna.core.shared.domain.Categories cat = new com.fyna.Fyna.core.shared.domain.Categories();
        cat.setId(UUID.randomUUID());
        rt.setCategories(cat);
        return rt;
    }

    private RecurringTransactions incomeRecurringDue(BigDecimal amount) {
        RecurringTransactions rt = new RecurringTransactions();
        rt.setId(UUID.randomUUID());
        rt.setUser(user);
        rt.setAccount(source);
        rt.setType(RecurringTransactionsTypes.INCOME);
        rt.setAmount(amount);
        rt.setDescription("Salário");
        rt.setFrequency(RecurringTransactionsFrequencyTypes.MONTHLY);
        rt.setFrequencyInterval(1);
        rt.setStartDate(LocalDate.now().minusDays(1));
        rt.setNextOccurrence(LocalDate.now());
        rt.setIsActive(true);
        return rt;
    }

    /** Verifica que a entidade Transactions tem o tipo esperado (usado em asserções inline). */
    @SuppressWarnings("unused")
    private static void assertType(Transactions tx, TransactionsType expected) {
        assertThat(tx.getType()).isEqualTo(expected);
    }
}
