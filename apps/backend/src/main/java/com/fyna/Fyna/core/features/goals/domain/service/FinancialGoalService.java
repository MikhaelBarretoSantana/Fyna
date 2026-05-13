package com.fyna.Fyna.core.features.goals.domain.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.goals.data.repository.FinancialGoalRepository;
import com.fyna.Fyna.core.features.goals.presentation.dto.CreateFinancialGoalRequest;
import com.fyna.Fyna.core.features.goals.presentation.dto.FinancialGoalResponse;
import com.fyna.Fyna.core.features.goals.presentation.dto.UpdateFinancialGoalRequest;
import com.fyna.Fyna.core.shared.domain.FinancialGoal;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.FinancialGoalPriority;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

@Service
public class FinancialGoalService {

    private final FinancialGoalRepository financialGoalRepository;
    private final UserRepository userRepository;

    public FinancialGoalService(FinancialGoalRepository financialGoalRepository, UserRepository userRepository) {
        this.financialGoalRepository = financialGoalRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<FinancialGoalResponse> getAllGoals(UUID userId) {
        return financialGoalRepository.findByUserId(userId).stream()
                .map(FinancialGoalResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<FinancialGoalResponse> getGoalsByStatus(UUID userId, FinancialGoalStatus status) {
        return financialGoalRepository.findByUserIdAndStatus(userId, status).stream()
                .map(FinancialGoalResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public FinancialGoalResponse getGoal(UUID id, UUID userId) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));
        return FinancialGoalResponse.from(goal);
    }

    @Transactional
    public FinancialGoalResponse createGoal(UUID userId, CreateFinancialGoalRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        FinancialGoal goal = new FinancialGoal();
        goal.setUser(user);
        goal.setName(request.name());
        goal.setDescription(request.description());
        goal.setIcon(request.icon());
        goal.setColor(request.color());
        goal.setTargetAmount(request.targetAmount());
        goal.setCurrentAmount(BigDecimal.ZERO);
        goal.setTargetDate(request.targetDate());
        goal.setStatus(FinancialGoalStatus.IN_PROGRESS);
        goal.setPriority(request.priority() != null ? request.priority() : FinancialGoalPriority.MEDIUM);

        goal = financialGoalRepository.save(goal);
        return FinancialGoalResponse.from(goal);
    }

    @Transactional
    public FinancialGoalResponse updateGoal(UUID id, UUID userId, UpdateFinancialGoalRequest request) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));

        if (request.name() != null) goal.setName(request.name());
        if (request.description() != null) goal.setDescription(request.description());
        if (request.icon() != null) goal.setIcon(request.icon());
        if (request.color() != null) goal.setColor(request.color());
        if (request.targetAmount() != null) goal.setTargetAmount(request.targetAmount());
        if (request.targetDate() != null) goal.setTargetDate(request.targetDate());
        if (request.priority() != null) goal.setPriority(request.priority());

        if (request.currentAmount() != null) {
            goal.setCurrentAmount(request.currentAmount());
            if (goal.getCurrentAmount().compareTo(goal.getTargetAmount()) >= 0
                    && goal.getStatus() == FinancialGoalStatus.IN_PROGRESS) {
                goal.setStatus(FinancialGoalStatus.COMPLETED);
                goal.setCompletedAt(Instant.now());
            }
        }

        if (request.status() != null) {
            goal.setStatus(request.status());
            if (request.status() == FinancialGoalStatus.COMPLETED && goal.getCompletedAt() == null) {
                goal.setCompletedAt(Instant.now());
            }
        }

        goal = financialGoalRepository.save(goal);
        return FinancialGoalResponse.from(goal);
    }

    @Transactional
    public void deleteGoal(UUID id, UUID userId) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));
        financialGoalRepository.delete(goal);
    }

    /**
     * Adiciona valor ao progresso de uma meta financeira.
     */
    @Transactional
    public FinancialGoalResponse addProgress(UUID id, UUID userId, BigDecimal amount) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));

        goal.setCurrentAmount(goal.getCurrentAmount().add(amount));

        if (goal.getCurrentAmount().compareTo(goal.getTargetAmount()) >= 0
                && goal.getStatus() == FinancialGoalStatus.IN_PROGRESS) {
            goal.setStatus(FinancialGoalStatus.COMPLETED);
            goal.setCompletedAt(Instant.now());
        }

        goal = financialGoalRepository.save(goal);
        return FinancialGoalResponse.from(goal);
    }
}
