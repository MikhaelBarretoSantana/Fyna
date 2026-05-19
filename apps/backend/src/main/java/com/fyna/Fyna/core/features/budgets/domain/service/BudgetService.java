package com.fyna.Fyna.core.features.budgets.domain.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.data.repository.BudgetRepository;
import com.fyna.Fyna.core.features.budgets.presentation.dto.BudgetResponse;
import com.fyna.Fyna.core.features.budgets.presentation.dto.CreateBudgetRequest;
import com.fyna.Fyna.core.features.budgets.presentation.dto.UpdateBudgetRequest;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.shared.domain.Budget;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.BudgetPeriodType;
import com.fyna.Fyna.core.shared.enums.NotificationType;

@Service
public class BudgetService {

    private static final Logger log = LoggerFactory.getLogger(BudgetService.class);
    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private final BudgetRepository budgetRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final NotificationService notificationService;

    public BudgetService(BudgetRepository budgetRepository, UserRepository userRepository,
            CategoryRepository categoryRepository, NotificationService notificationService) {
        this.budgetRepository = budgetRepository;
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public List<BudgetResponse> getActiveBudgets(UUID userId) {
        return budgetRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .peek(this::rollOverIfNeeded)
                .map(BudgetResponse::from)
                .toList();
    }

    @Transactional
    public List<BudgetResponse> getCurrentBudgets(UUID userId) {
        return budgetRepository.findActiveBudgetsForDate(userId, LocalDate.now()).stream()
                .peek(this::rollOverIfNeeded)
                .map(BudgetResponse::from)
                .toList();
    }

    @Transactional
    public BudgetResponse getBudget(UUID id, UUID userId) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget", "id", id));
        rollOverIfNeeded(budget);
        return BudgetResponse.from(budget);
    }

    @Transactional
    public BudgetResponse createBudget(UUID userId, CreateBudgetRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Budget budget = new Budget();
        budget.setUser(user);
        budget.setName(request.name());
        budget.setAmountLimit(request.amountLimit());
        budget.setAmountSpent(BigDecimal.ZERO);
        budget.setPeriodType(request.periodType());
        budget.setStartDate(request.startDate());
        budget.setEndDate(request.endDate());
        budget.setCurrentPeriodStart(request.startDate());
        budget.setAlertThreshold(request.alertThreshold() != null ? request.alertThreshold() : new BigDecimal("80.00"));
        budget.setAlertEnabled(request.alertEnabled() != null ? request.alertEnabled() : true);
        budget.setIsActive(true);

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            budget.setCategory(category);
        }

        budget = budgetRepository.save(budget);
        return BudgetResponse.from(budget);
    }

    @Transactional
    public BudgetResponse updateBudget(UUID id, UUID userId, UpdateBudgetRequest request) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget", "id", id));

        if (request.name() != null) budget.setName(request.name());
        if (request.endDate() != null) budget.setEndDate(request.endDate());
        if (request.alertThreshold() != null) budget.setAlertThreshold(request.alertThreshold());
        if (request.alertEnabled() != null) budget.setAlertEnabled(request.alertEnabled());
        if (request.isActive() != null) budget.setIsActive(request.isActive());

        // Mudanças que invalidam o consumo acumulado:
        //  - troca de categoria: o histórico era de outra categoria
        //  - aumento do limite: redefine a base de cálculo (alerta precisa re-disparar)
        boolean resetSpending = false;

        if (request.categoryId() != null) {
            UUID currentCategoryId = budget.getCategory() != null ? budget.getCategory().getId() : null;
            if (!request.categoryId().equals(currentCategoryId)) {
                Categories category = categoryRepository.findById(request.categoryId())
                        .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
                budget.setCategory(category);
                resetSpending = true;
            }
        }

        if (request.amountLimit() != null
                && (budget.getAmountLimit() == null
                    || request.amountLimit().compareTo(budget.getAmountLimit()) != 0)) {
            budget.setAmountLimit(request.amountLimit());
            resetSpending = true;
        }

        if (resetSpending) {
            budget.setAmountSpent(BigDecimal.ZERO);
            budget.setLastAlertThreshold(BigDecimal.ZERO);
        }

        budget = budgetRepository.save(budget);
        return BudgetResponse.from(budget);
    }

    @Transactional
    public void deleteBudget(UUID id, UUID userId) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget", "id", id));
        budget.setIsActive(false);
        budgetRepository.save(budget);
    }

    /**
     * Aplica um delta (positivo ou negativo) ao consumo dos orçamentos ativos
     * que cobrem {@code categoryId} e contêm {@code transactionDate} no período corrente.
     *
     * <p>Mantém invariantes: faz rollover antes de aplicar, ignora deltas para
     * transações fora do período corrente (retroativas pós-rollover), e nunca
     * deixa {@code amountSpent} negativo. Alertas só disparam em deltas positivos.
     *
     * @param userId          dono dos orçamentos
     * @param categoryId      categoria da transação; se {@code null}, nada acontece
     * @param delta           valor a somar (use negativo para reverter)
     * @param transactionDate data efetiva da transação que originou o delta
     */
    @Transactional
    public void applyTransactionDelta(UUID userId, UUID categoryId, BigDecimal delta, LocalDate transactionDate) {
        if (delta == null || delta.signum() == 0) return;

        LocalDate refDate = transactionDate != null ? transactionDate : LocalDate.now();

        // Budgets específicos da categoria (se informada)
        if (categoryId != null) {
            for (Budget budget : budgetRepository.findActiveBudgetsByCategoryForDate(userId, categoryId, refDate)) {
                applyDeltaToBudget(userId, budget, delta, refDate);
            }
        }

        // Budgets globais (sem categoria) — somam TODA despesa paga do usuário no período.
        // Aplica mesmo quando categoryId é null (ex.: transação sem categoria ainda em classificação).
        for (Budget budget : budgetRepository.findActiveGlobalBudgetsForDate(userId, refDate)) {
            applyDeltaToBudget(userId, budget, delta, refDate);
        }
    }

    private void applyDeltaToBudget(UUID userId, Budget budget, BigDecimal delta, LocalDate refDate) {
        rollOverIfNeeded(budget);

        if (!isInsideCurrentPeriod(budget, refDate)) {
            log.debug("Pulando budget {} pois transactionDate {} está fora do período corrente {} - {}",
                    budget.getId(), refDate, budget.getCurrentPeriodStart(),
                    nextPeriodStart(budget.getCurrentPeriodStart(), budget.getPeriodType(), budget.getEndDate()));
            return;
        }

        BigDecimal newSpent = budget.getAmountSpent().add(delta);
        if (newSpent.signum() < 0) newSpent = BigDecimal.ZERO;
        budget.setAmountSpent(newSpent);

        if (delta.signum() > 0) {
            maybeFireBudgetAlert(userId, budget);
        }
        budgetRepository.save(budget);
    }

    /**
     * Atualiza o valor gasto em orçamentos ativos para uma categoria específica.
     * @deprecated Use {@link #applyTransactionDelta(UUID, UUID, BigDecimal, LocalDate)} passando
     *             {@code transactionDate} para evitar contabilização cruzada de períodos.
     */
    @Deprecated
    @Transactional
    public void updateBudgetSpending(UUID userId, UUID categoryId, BigDecimal amount) {
        applyTransactionDelta(userId, categoryId, amount, LocalDate.now());
    }

    /**
     * Avança {@code currentPeriodStart} de orçamentos periódicos até cobrir hoje,
     * resetando {@code amountSpent} e {@code lastAlertThreshold} a cada virada.
     * Budgets CUSTOM não são afetados (endDate é a fronteira real).
     * Desativa o budget se {@code currentPeriodStart} ultrapassar {@code endDate}.
     */
    private void rollOverIfNeeded(Budget budget) {
        if (budget.getPeriodType() == BudgetPeriodType.CUSTOM) return;
        if (Boolean.FALSE.equals(budget.getIsActive())) return;

        LocalDate today = LocalDate.now();
        LocalDate nextStart = nextPeriodStart(budget.getCurrentPeriodStart(), budget.getPeriodType(), budget.getEndDate());

        boolean rolled = false;
        while (!today.isBefore(nextStart) && !nextStart.isAfter(budget.getEndDate())) {
            budget.setCurrentPeriodStart(nextStart);
            budget.setAmountSpent(BigDecimal.ZERO);
            budget.setLastAlertThreshold(BigDecimal.ZERO);
            nextStart = nextPeriodStart(nextStart, budget.getPeriodType(), budget.getEndDate());
            rolled = true;
        }

        if (budget.getCurrentPeriodStart().isAfter(budget.getEndDate())) {
            budget.setIsActive(false);
            rolled = true;
        }

        if (rolled) {
            budgetRepository.save(budget);
        }
    }

    private boolean isInsideCurrentPeriod(Budget budget, LocalDate date) {
        if (date.isBefore(budget.getCurrentPeriodStart())) return false;
        LocalDate periodEndExclusive = budget.getPeriodType() == BudgetPeriodType.CUSTOM
                ? budget.getEndDate().plusDays(1)
                : nextPeriodStart(budget.getCurrentPeriodStart(), budget.getPeriodType(), budget.getEndDate());
        return date.isBefore(periodEndExclusive);
    }

    private LocalDate nextPeriodStart(LocalDate start, BudgetPeriodType type, LocalDate endDate) {
        return switch (type) {
            case WEEKLY -> start.plusWeeks(1);
            case BIWEEKLY -> start.plusWeeks(2);
            case MONTHLY -> start.plusMonths(1);
            case QUARTERLY -> start.plusMonths(3);
            case YEARLY -> start.plusYears(1);
            case CUSTOM -> endDate.plusDays(1);
        };
    }

    /**
     * Dispara BUDGET_ALERT quando o consumo atinge alertThreshold ou 100%.
     * Idempotente: usa lastAlertThreshold para garantir 1 notificação por faixa.
     */
    private void maybeFireBudgetAlert(UUID userId, Budget budget) {
        if (!Boolean.TRUE.equals(budget.getAlertEnabled())) return;
        if (budget.getAmountLimit() == null || budget.getAmountLimit().signum() <= 0) return;

        BigDecimal percentageUsed = budget.getAmountSpent()
                .multiply(HUNDRED)
                .divide(budget.getAmountLimit(), 2, RoundingMode.HALF_UP);

        BigDecimal lastNotified = budget.getLastAlertThreshold() != null
                ? budget.getLastAlertThreshold() : BigDecimal.ZERO;
        BigDecimal threshold = budget.getAlertThreshold();

        BigDecimal newThreshold = null;
        String title = null;
        String message = null;

        if (percentageUsed.compareTo(HUNDRED) >= 0 && lastNotified.compareTo(HUNDRED) < 0) {
            newThreshold = HUNDRED;
            title = "Orçamento estourado";
            message = String.format("Você atingiu 100%% do orçamento \"%s\".", budget.getName());
        } else if (percentageUsed.compareTo(threshold) >= 0 && lastNotified.compareTo(threshold) < 0
                && percentageUsed.compareTo(HUNDRED) < 0) {
            newThreshold = threshold;
            title = "Alerta de orçamento";
            message = String.format("Você atingiu %s%% do orçamento \"%s\".",
                    percentageUsed.stripTrailingZeros().toPlainString(), budget.getName());
        }

        if (newThreshold == null) return;

        String metadata = String.format("{\"budgetId\":\"%s\",\"percentage\":\"%s\"}",
                budget.getId(), percentageUsed.toPlainString());
        notificationService.createNotification(
                userId,
                NotificationType.BUDGET_ALERT,
                title,
                message,
                "/budgets/" + budget.getId(),
                metadata
        );
        budget.setLastAlertThreshold(newThreshold);
    }
}
