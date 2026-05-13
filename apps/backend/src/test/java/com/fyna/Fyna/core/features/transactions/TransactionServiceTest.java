package com.fyna.Fyna.core.features.transactions;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.ai.infrastructure.AIEngineClient;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.features.transactions.domain.service.TransactionService;
import com.fyna.Fyna.core.features.transactions.presentation.dto.CreateTransactionRequest;
import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@ExtendWith(MockitoExtension.class)
class TransactionServiceTest {

    @Mock TransactionRepository transactionRepository;
    @Mock AccountRepository accountRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock UserRepository userRepository;
    @Mock AIEngineClient aiEngineClient;

    @InjectMocks TransactionService transactionService;

    private UUID userId;
    private User fakeUser;
    private Accounts fakeAccount;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();

        fakeUser = new User();
        fakeUser.setId(userId);
        fakeUser.setLogin("joao");

        fakeAccount = new Accounts();
        fakeAccount.setId(UUID.randomUUID());
        fakeAccount.setCurrentBalance(BigDecimal.valueOf(1000));
    }

    // ─── createTransaction ───────────────────────────────────────────────

    @Test
    void createTransaction_semCategoria_deveDisparar_AIClassification() {
        var request = new CreateTransactionRequest(
                fakeAccount.getId(), null, TransactionsType.EXPENSE,
                BigDecimal.valueOf(50), "Almoço", null,
                LocalDate.now(), null, true, null, null
        );

        var savedTx = new Transactions();
        savedTx.setId(UUID.randomUUID());
        savedTx.setUser(fakeUser);
        savedTx.setAccount(fakeAccount);
        savedTx.setType(TransactionsType.EXPENSE);
        savedTx.setAmount(BigDecimal.valueOf(50));
        savedTx.setDescription("Almoço");
        savedTx.setTransactionDate(LocalDate.now());
        savedTx.setIsPaid(true);
        savedTx.setIsRecurring(false);

        when(userRepository.findById(userId)).thenReturn(Optional.of(fakeUser));
        when(accountRepository.findByIdAndUserId(fakeAccount.getId(), userId))
                .thenReturn(Optional.of(fakeAccount));
        when(transactionRepository.save(any())).thenReturn(savedTx);
        when(accountRepository.save(any())).thenReturn(fakeAccount);

        transactionService.createTransaction(userId, request);

        verify(aiEngineClient).classifyTransaction(
                any(UUID.class), any(UUID.class),
                any(String.class), any(BigDecimal.class), any(String.class)
        );
    }

    @Test
    void createTransaction_comCategoria_naoDispara_AIClassification() {
        UUID categoryId = UUID.randomUUID();
        var request = new CreateTransactionRequest(
                fakeAccount.getId(), categoryId, TransactionsType.EXPENSE,
                BigDecimal.valueOf(50), "Almoço", null,
                LocalDate.now(), null, true, null, null
        );

        var savedTx = new Transactions();
        savedTx.setId(UUID.randomUUID());
        savedTx.setUser(fakeUser);
        savedTx.setAccount(fakeAccount);
        savedTx.setType(TransactionsType.EXPENSE);
        savedTx.setAmount(BigDecimal.valueOf(50));
        savedTx.setDescription("Almoço");
        savedTx.setTransactionDate(LocalDate.now());
        savedTx.setIsPaid(true);
        savedTx.setIsRecurring(false);

        when(userRepository.findById(userId)).thenReturn(Optional.of(fakeUser));
        when(accountRepository.findByIdAndUserId(fakeAccount.getId(), userId))
                .thenReturn(Optional.of(fakeAccount));
        when(categoryRepository.findById(categoryId)).thenReturn(Optional.of(new com.fyna.Fyna.core.shared.domain.Categories()));
        when(transactionRepository.save(any())).thenReturn(savedTx);
        when(accountRepository.save(any())).thenReturn(fakeAccount);

        transactionService.createTransaction(userId, request);

        verify(aiEngineClient, never()).classifyTransaction(any(), any(), any(), any(), any());
    }

    @Test
    void createTransaction_despesaPaga_deveDebitarSaldo() {
        var request = new CreateTransactionRequest(
                fakeAccount.getId(), null, TransactionsType.EXPENSE,
                BigDecimal.valueOf(200), "Supermercado", null,
                LocalDate.now(), null, true, null, null
        );

        var savedTx = new Transactions();
        savedTx.setId(UUID.randomUUID());
        savedTx.setUser(fakeUser);
        savedTx.setAccount(fakeAccount);
        savedTx.setType(TransactionsType.EXPENSE);
        savedTx.setAmount(BigDecimal.valueOf(200));
        savedTx.setDescription("Supermercado");
        savedTx.setTransactionDate(LocalDate.now());
        savedTx.setIsPaid(true);
        savedTx.setIsRecurring(false);

        when(userRepository.findById(userId)).thenReturn(Optional.of(fakeUser));
        when(accountRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.of(fakeAccount));
        when(transactionRepository.save(any())).thenReturn(savedTx);
        when(accountRepository.save(any())).thenReturn(fakeAccount);

        transactionService.createTransaction(userId, request);

        // O saldo deve ter sido atualizado (verify que accountRepository.save foi chamado)
        verify(accountRepository).save(fakeAccount);
        assertThat(fakeAccount.getCurrentBalance()).isEqualByComparingTo(BigDecimal.valueOf(800));
    }

    @Test
    void createTransaction_usuarioNaoEncontrado_deveLancarExcecao() {
        var request = new CreateTransactionRequest(
                UUID.randomUUID(), null, TransactionsType.EXPENSE,
                BigDecimal.valueOf(50), "Almoço", null,
                LocalDate.now(), null, true, null, null
        );

        when(userRepository.findById(userId)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.createTransaction(userId, request))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void createTransaction_contaNaoEncontrada_deveLancarExcecao() {
        var request = new CreateTransactionRequest(
                UUID.randomUUID(), null, TransactionsType.EXPENSE,
                BigDecimal.valueOf(50), "Almoço", null,
                LocalDate.now(), null, true, null, null
        );

        when(userRepository.findById(userId)).thenReturn(Optional.of(fakeUser));
        when(accountRepository.findByIdAndUserId(any(), any())).thenReturn(Optional.empty());

        assertThatThrownBy(() -> transactionService.createTransaction(userId, request))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
