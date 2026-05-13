package com.fyna.Fyna.core.features.budgets.domain.service;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.data.repository.BudgetRepository;
import com.fyna.Fyna.core.features.budgets.presentation.dto.BudgetResponse;
import com.fyna.Fyna.core.features.budgets.presentation.dto.CreateBudgetRequest;
import com.fyna.Fyna.core.features.budgets.presentation.dto.UpdateBudgetRequest;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.shared.domain.Budget;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.User;

import java.math.BigDecimal;

@Service
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;

    public BudgetService(BudgetRepository budgetRepository, UserRepository userRepository,
            CategoryRepository categoryRepository) {
        this.budgetRepository = budgetRepository;
        this.userRepository = userRepository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> getActiveBudgets(UUID userId) {
        return budgetRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(BudgetResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> getCurrentBudgets(UUID userId) {
        return budgetRepository.findActiveBudgetsForDate(userId, LocalDate.now()).stream()
                .map(BudgetResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public BudgetResponse getBudget(UUID id, UUID userId) {
        Budget budget = budgetRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Budget", "id", id));
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
        if (request.amountLimit() != null) budget.setAmountLimit(request.amountLimit());
        if (request.endDate() != null) budget.setEndDate(request.endDate());
        if (request.alertThreshold() != null) budget.setAlertThreshold(request.alertThreshold());
        if (request.alertEnabled() != null) budget.setAlertEnabled(request.alertEnabled());
        if (request.isActive() != null) budget.setIsActive(request.isActive());

        if (request.categoryId() != null) {
            Categories category = categoryRepository.findById(request.categoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.categoryId()));
            budget.setCategory(category);
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
     * Atualiza o valor gasto em orçamentos ativos para uma categoria específica.
     * Chamado quando uma transação de despesa é criada.
     */
    @Transactional
    public void updateBudgetSpending(UUID userId, UUID categoryId, BigDecimal amount) {
        List<Budget> budgets = budgetRepository.findActiveBudgetsByCategoryForDate(userId, categoryId, LocalDate.now());
        for (Budget budget : budgets) {
            budget.setAmountSpent(budget.getAmountSpent().add(amount));
            budgetRepository.save(budget);
        }
    }
}
