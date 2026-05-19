package com.fyna.Fyna.core.features.budgets;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.atLeastOnce;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.data.repository.BudgetRepository;
import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.shared.domain.Budget;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.BudgetPeriodType;
import com.fyna.Fyna.core.shared.enums.NotificationType;

@ExtendWith(MockitoExtension.class)
class BudgetServiceTest {

    @Mock BudgetRepository budgetRepository;
    @Mock UserRepository userRepository;
    @Mock CategoryRepository categoryRepository;
    @Mock NotificationService notificationService;

    @InjectMocks BudgetService service;

    private UUID userId;
    private UUID categoryId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID();
        categoryId = UUID.randomUUID();
    }

    // ─── applyTransactionDelta ─────────────────────────────────────────────

    @Test
    void applyDelta_positivo_acumulaConsumo() {
        Budget budget = monthlyBudget(new BigDecimal("500"), BigDecimal.ZERO);
        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("100"), LocalDate.now());

        assertThat(budget.getAmountSpent()).isEqualByComparingTo("100");
        verify(budgetRepository).save(budget);
    }

    @Test
    void applyDelta_negativo_reduzConsumoEClampaEmZero() {
        Budget budget = monthlyBudget(new BigDecimal("500"), new BigDecimal("80"));
        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        // Delta -120 levaria a -40 → deve ser clampado em 0
        service.applyTransactionDelta(userId, categoryId, new BigDecimal("-120"), LocalDate.now());

        assertThat(budget.getAmountSpent()).isEqualByComparingTo("0");
    }

    @Test
    void applyDelta_negativo_naoDisparaAlerta() {
        Budget budget = monthlyBudget(new BigDecimal("100"), new BigDecimal("70"));
        budget.setAlertEnabled(true);
        budget.setAlertThreshold(new BigDecimal("50"));
        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("-20"), LocalDate.now());

        verify(notificationService, never()).createNotification(any(), any(NotificationType.class),
                anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void applyDelta_atingeThreshold_disparaAlerta() {
        Budget budget = monthlyBudget(new BigDecimal("100"), BigDecimal.ZERO);
        budget.setAlertEnabled(true);
        budget.setAlertThreshold(new BigDecimal("80"));
        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("85"), LocalDate.now());

        verify(notificationService).createNotification(eq(userId), eq(NotificationType.BUDGET_ALERT),
                anyString(), anyString(), anyString(), anyString());
    }

    @Test
    void applyDelta_budgetGlobalSemCategoria_acumulaMesmoSemCategoria() {
        Budget global = monthlyGlobalBudget(new BigDecimal("1000"), BigDecimal.ZERO);
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of(global));
        // Nenhum budget por categoria

        service.applyTransactionDelta(userId, null, new BigDecimal("250"), LocalDate.now());

        assertThat(global.getAmountSpent()).isEqualByComparingTo("250");
    }

    @Test
    void applyDelta_categoriaEspecificaEGlobal_ambosAcumulam() {
        Budget categoryBudget = monthlyBudget(new BigDecimal("500"), BigDecimal.ZERO);
        Budget global = monthlyGlobalBudget(new BigDecimal("2000"), BigDecimal.ZERO);
        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(categoryBudget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of(global));

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("100"), LocalDate.now());

        assertThat(categoryBudget.getAmountSpent()).isEqualByComparingTo("100");
        assertThat(global.getAmountSpent()).isEqualByComparingTo("100");
    }

    @Test
    void applyDelta_zero_naoFazNada() {
        service.applyTransactionDelta(userId, categoryId, BigDecimal.ZERO, LocalDate.now());
        verify(budgetRepository, never()).findActiveBudgetsByCategoryForDate(any(), any(), any());
        verify(budgetRepository, never()).findActiveGlobalBudgetsForDate(any(), any());
    }

    // ─── rollover periódico ────────────────────────────────────────────────

    @Test
    void rollover_monthlyBudgetVencido_resetaConsumoEAvancaPeriodo() {
        // Budget MONTHLY iniciado há 2 meses, ainda dentro da janela startDate/endDate
        LocalDate twoMonthsAgo = LocalDate.now().minusMonths(2);
        Budget budget = new Budget();
        budget.setId(UUID.randomUUID());
        budget.setUser(userWithId());
        budget.setName("Lazer");
        budget.setAmountLimit(new BigDecimal("300"));
        budget.setAmountSpent(new BigDecimal("280")); // consumo do mês passado
        budget.setLastAlertThreshold(new BigDecimal("80"));
        budget.setAlertEnabled(true);
        budget.setAlertThreshold(new BigDecimal("80"));
        budget.setPeriodType(BudgetPeriodType.MONTHLY);
        budget.setStartDate(twoMonthsAgo);
        budget.setEndDate(LocalDate.now().plusYears(1));
        budget.setCurrentPeriodStart(twoMonthsAgo);
        budget.setIsActive(true);

        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("50"), LocalDate.now());

        // currentPeriodStart deve ter avançado para perto de hoje (mês corrente)
        assertThat(budget.getCurrentPeriodStart()).isAfter(twoMonthsAgo);
        // Após reset, soma só 50 (novo período)
        assertThat(budget.getAmountSpent()).isEqualByComparingTo("50");
        // Alert threshold também zerado e potencialmente re-aplicado se cruzou
        verify(budgetRepository, atLeastOnce()).save(budget);
    }

    @Test
    void rollover_customBudget_naoReseta() {
        Budget budget = new Budget();
        budget.setId(UUID.randomUUID());
        budget.setUser(userWithId());
        budget.setName("Reforma");
        budget.setAmountLimit(new BigDecimal("10000"));
        budget.setAmountSpent(new BigDecimal("7000"));
        budget.setLastAlertThreshold(new BigDecimal("80"));
        budget.setAlertEnabled(true);
        budget.setAlertThreshold(new BigDecimal("80"));
        budget.setPeriodType(BudgetPeriodType.CUSTOM);
        budget.setStartDate(LocalDate.now().minusMonths(6));
        budget.setEndDate(LocalDate.now().plusYears(1));
        budget.setCurrentPeriodStart(LocalDate.now().minusMonths(6));
        budget.setIsActive(true);

        when(budgetRepository.findActiveBudgetsByCategoryForDate(eq(userId), eq(categoryId), any()))
                .thenReturn(List.of(budget));
        when(budgetRepository.findActiveGlobalBudgetsForDate(eq(userId), any())).thenReturn(List.of());

        service.applyTransactionDelta(userId, categoryId, new BigDecimal("100"), LocalDate.now());

        // CUSTOM não rola; acumula 7000 + 100 = 7100
        assertThat(budget.getAmountSpent()).isEqualByComparingTo("7100");
        assertThat(budget.getCurrentPeriodStart()).isEqualTo(LocalDate.now().minusMonths(6));
    }

    // ─── helpers ───────────────────────────────────────────────────────────

    private User userWithId() {
        User u = new User();
        u.setId(userId);
        return u;
    }

    private Budget monthlyBudget(BigDecimal limit, BigDecimal spent) {
        Budget b = new Budget();
        b.setId(UUID.randomUUID());
        b.setUser(userWithId());
        Categories cat = new Categories();
        cat.setId(categoryId);
        b.setCategory(cat);
        b.setName("Test");
        b.setAmountLimit(limit);
        b.setAmountSpent(spent);
        b.setLastAlertThreshold(BigDecimal.ZERO);
        b.setAlertEnabled(false);
        b.setAlertThreshold(new BigDecimal("80"));
        b.setPeriodType(BudgetPeriodType.MONTHLY);
        b.setStartDate(LocalDate.now().withDayOfMonth(1));
        b.setEndDate(LocalDate.now().plusYears(1));
        b.setCurrentPeriodStart(LocalDate.now().withDayOfMonth(1));
        b.setIsActive(true);
        return b;
    }

    private Budget monthlyGlobalBudget(BigDecimal limit, BigDecimal spent) {
        Budget b = monthlyBudget(limit, spent);
        b.setCategory(null);
        return b;
    }
}
