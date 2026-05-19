package com.fyna.Fyna.core.features.goals.domain.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.goals.data.repository.FinancialGoalRepository;
import com.fyna.Fyna.core.features.goals.presentation.dto.CreateFinancialGoalRequest;
import com.fyna.Fyna.core.features.goals.presentation.dto.FinancialGoalResponse;
import com.fyna.Fyna.core.features.goals.presentation.dto.UpdateFinancialGoalRequest;
import com.fyna.Fyna.core.features.notifications.domain.service.NotificationService;
import com.fyna.Fyna.core.shared.domain.FinancialGoal;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.FinancialGoalPriority;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;
import com.fyna.Fyna.core.shared.enums.NotificationType;

@Service
public class FinancialGoalService {

    private static final BigDecimal HUNDRED = new BigDecimal("100");

    private final FinancialGoalRepository financialGoalRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    public FinancialGoalService(FinancialGoalRepository financialGoalRepository, UserRepository userRepository,
            NotificationService notificationService) {
        this.financialGoalRepository = financialGoalRepository;
        this.userRepository = userRepository;
        this.notificationService = notificationService;
    }

    @Transactional(readOnly = true)
    public List<FinancialGoalResponse> getAllGoals(UUID userId) {
        return financialGoalRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(FinancialGoalResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<FinancialGoalResponse> getGoalsByStatus(UUID userId, FinancialGoalStatus status) {
        return financialGoalRepository.findByUserIdAndStatusAndIsActiveTrue(userId, status).stream()
                .map(FinancialGoalResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public FinancialGoalResponse getGoal(UUID id, UUID userId) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserIdAndIsActiveTrue(id, userId)
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
        FinancialGoal goal = financialGoalRepository.findByIdAndUserIdAndIsActiveTrue(id, userId)
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
            maybeFireGoalMilestone(userId, goal);
        }

        if (request.status() != null) {
            if (request.status() == FinancialGoalStatus.COMPLETED
                    && goal.getCurrentAmount().compareTo(goal.getTargetAmount()) < 0) {
                throw new BadRequestException(
                        "Meta não pode ser marcada como concluída sem atingir o valor alvo");
            }
            goal.setStatus(request.status());
            if (request.status() == FinancialGoalStatus.COMPLETED && goal.getCompletedAt() == null) {
                goal.setCompletedAt(Instant.now());
            }
        }

        goal = financialGoalRepository.save(goal);
        return FinancialGoalResponse.from(goal);
    }

    /**
     * Arquiva a meta (soft-delete). Mantém histórico para notificações já enviadas
     * que referenciam {@code /goals/{id}}.
     */
    @Transactional
    public void deleteGoal(UUID id, UUID userId) {
        FinancialGoal goal = financialGoalRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));
        if (Boolean.FALSE.equals(goal.getIsActive())) return;
        goal.setIsActive(false);
        financialGoalRepository.save(goal);
    }

    /**
     * Adiciona valor ao progresso de uma meta financeira.
     * Exige metas em andamento e valor positivo — para correções use {@link #updateGoal}.
     */
    @Transactional
    public FinancialGoalResponse addProgress(UUID id, UUID userId, BigDecimal amount) {
        if (amount == null || amount.signum() <= 0) {
            throw new BadRequestException("O valor adicionado ao progresso deve ser positivo");
        }
        FinancialGoal goal = financialGoalRepository.findByIdAndUserIdAndIsActiveTrue(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("FinancialGoal", "id", id));

        if (goal.getStatus() != FinancialGoalStatus.IN_PROGRESS) {
            throw new BadRequestException(
                    "Só é possível adicionar progresso a metas em andamento (status atual: " + goal.getStatus() + ")");
        }

        goal.setCurrentAmount(goal.getCurrentAmount().add(amount));

        if (goal.getCurrentAmount().compareTo(goal.getTargetAmount()) >= 0
                && goal.getStatus() == FinancialGoalStatus.IN_PROGRESS) {
            goal.setStatus(FinancialGoalStatus.COMPLETED);
            goal.setCompletedAt(Instant.now());
        }

        maybeFireGoalMilestone(userId, goal);

        goal = financialGoalRepository.save(goal);
        return FinancialGoalResponse.from(goal);
    }

    /**
     * Dispara GOAL_PROGRESS em 50% / 75% e GOAL_COMPLETED em 100%.
     * Idempotente por marco; se o valor recuar para uma banda inferior,
     * o {@code lastProgressMilestone} é rebaixado para que novas subidas
     * voltem a notificar — comportamento simétrico, importante para correções.
     */
    private void maybeFireGoalMilestone(UUID userId, FinancialGoal goal) {
        if (goal.getTargetAmount() == null || goal.getTargetAmount().signum() <= 0) return;

        BigDecimal percentage = goal.getCurrentAmount()
                .multiply(HUNDRED)
                .divide(goal.getTargetAmount(), 2, RoundingMode.HALF_UP);

        short lastMilestone = goal.getLastProgressMilestone() != null
                ? goal.getLastProgressMilestone()
                : (short) 0;

        // Banda corrente (chão do marco): 0/50/75/100
        short currentBand;
        if (percentage.compareTo(HUNDRED) >= 0) currentBand = 100;
        else if (percentage.compareTo(new BigDecimal("75")) >= 0) currentBand = 75;
        else if (percentage.compareTo(new BigDecimal("50")) >= 0) currentBand = 50;
        else currentBand = 0;

        // Se o valor recuou abaixo do último marco notificado, rebaixa lastMilestone
        // para a banda atual — assim, ao subir novamente, o marco re-dispara.
        if (currentBand < lastMilestone) {
            goal.setLastProgressMilestone(currentBand);
            lastMilestone = currentBand;
        }

        short newMilestone = currentBand;
        if (newMilestone <= lastMilestone) return;

        NotificationType type = newMilestone == 100
                ? NotificationType.GOAL_COMPLETED
                : NotificationType.GOAL_PROGRESS;
        String title = newMilestone == 100 ? "Meta atingida!" : "Progresso da meta";
        String message = newMilestone == 100
                ? String.format("Parabéns! Você concluiu a meta \"%s\".", goal.getName())
                : String.format("Você atingiu %d%% da meta \"%s\".", newMilestone, goal.getName());

        String metadata = String.format("{\"goalId\":\"%s\",\"milestone\":%d}",
                goal.getId(), newMilestone);
        notificationService.createNotification(
                userId,
                type,
                title,
                message,
                "/goals/" + goal.getId(),
                metadata
        );
        goal.setLastProgressMilestone(newMilestone);
    }
}
