package com.fyna.Fyna.core.features.ai.domain.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.ai.data.repository.AIClassificationRepository;
import com.fyna.Fyna.core.features.ai.data.repository.InvestmentRecommendationRepository;
import com.fyna.Fyna.core.features.ai.data.repository.SpendingPatternRepository;
import com.fyna.Fyna.core.features.ai.data.repository.SpendingPredictionRepository;
import com.fyna.Fyna.core.features.ai.presentation.dto.AIClassificationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.InvestmentRecommendationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPatternResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPredictionResponse;
import com.fyna.Fyna.core.features.budgets.domain.service.BudgetService;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.shared.domain.AIClassifications;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.InvestmentRecommendation;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.SpendingPatternType;
import com.fyna.Fyna.core.shared.enums.TransactionsType;

@Service
public class AIInsightsService {

    private final InvestmentRecommendationRepository recommendationRepository;
    private final SpendingPredictionRepository predictionRepository;
    private final SpendingPatternRepository patternRepository;
    private final AIClassificationRepository classificationRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetService budgetService;

    public AIInsightsService(InvestmentRecommendationRepository recommendationRepository,
            SpendingPredictionRepository predictionRepository, SpendingPatternRepository patternRepository,
            AIClassificationRepository classificationRepository, CategoryRepository categoryRepository,
            TransactionRepository transactionRepository, BudgetService budgetService) {
        this.recommendationRepository = recommendationRepository;
        this.predictionRepository = predictionRepository;
        this.patternRepository = patternRepository;
        this.classificationRepository = classificationRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.budgetService = budgetService;
    }

    // ================= Investment Recommendations =================

    @Transactional(readOnly = true)
    public PageResponse<InvestmentRecommendationResponse> getRecommendations(UUID userId, Pageable pageable) {
        Page<InvestmentRecommendationResponse> page = recommendationRepository
                .findByUserIdOrderByGeneratedAtDesc(userId, pageable)
                .map(InvestmentRecommendationResponse::from);
        return PageResponse.of(page);
    }

    @Transactional(readOnly = true)
    public List<InvestmentRecommendationResponse> getUnviewedRecommendations(UUID userId) {
        return recommendationRepository.findByUserIdAndWasViewedFalseOrderByGeneratedAtDesc(userId).stream()
                .map(InvestmentRecommendationResponse::from)
                .toList();
    }

    @Transactional
    public InvestmentRecommendationResponse markRecommendationAsViewed(UUID id, UUID userId) {
        InvestmentRecommendation rec = recommendationRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("InvestmentRecommendation", "id", id));
        rec.setWasViewed(true);
        rec.setViewedAt(Instant.now());
        rec = recommendationRepository.save(rec);
        return InvestmentRecommendationResponse.from(rec);
    }

    @Transactional
    public InvestmentRecommendationResponse markRecommendationAsFollowed(UUID id, UUID userId) {
        InvestmentRecommendation rec = recommendationRepository.findByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("InvestmentRecommendation", "id", id));
        if (Boolean.TRUE.equals(rec.getWasFollowed())) {
            return InvestmentRecommendationResponse.from(rec);
        }
        rec.setWasFollowed(true);
        if (!rec.getWasViewed()) {
            rec.setWasViewed(true);
            rec.setViewedAt(Instant.now());
        }
        rec = recommendationRepository.save(rec);
        return InvestmentRecommendationResponse.from(rec);
    }

    // ================= Spending Predictions =================

    @Transactional(readOnly = true)
    public List<SpendingPredictionResponse> getPredictions(UUID userId) {
        return predictionRepository.findByUserIdOrderByPredictionDateDesc(userId).stream()
                .map(SpendingPredictionResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SpendingPredictionResponse> getPredictionsByDateRange(UUID userId, LocalDate startDate,
            LocalDate endDate) {
        return predictionRepository.findByUserIdAndDateRange(userId, startDate, endDate).stream()
                .map(SpendingPredictionResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SpendingPredictionResponse> getPredictionsByCategory(UUID userId, UUID categoryId) {
        return predictionRepository.findByUserIdAndCategoryIdOrderByPredictionDateDesc(userId, categoryId).stream()
                .map(SpendingPredictionResponse::from)
                .toList();
    }

    // ================= Spending Patterns =================

    @Transactional(readOnly = true)
    public List<SpendingPatternResponse> getActivePatterns(UUID userId) {
        return patternRepository.findByUserIdAndIsActiveTrueOrderByDetectedAtDesc(userId).stream()
                .map(SpendingPatternResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<SpendingPatternResponse> getPatternsByType(UUID userId, SpendingPatternType type) {
        return patternRepository.findByUserIdAndPatternTypeAndIsActiveTrueOrderByDetectedAtDesc(userId, type).stream()
                .map(SpendingPatternResponse::from)
                .toList();
    }

    // ================= AI Classifications =================

    @Transactional(readOnly = true)
    public List<AIClassificationResponse> getPendingClassifications(UUID userId) {
        return classificationRepository.findPendingClassifications(userId).stream()
                .map(AIClassificationResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AIClassificationResponse getClassificationByTransaction(UUID userId, UUID transactionId) {
        AIClassifications classification = classificationRepository.findByTransactionsId(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("AIClassification", "transactionId", transactionId));
        if (!ownsClassification(classification, userId)) {
            throw new ResourceNotFoundException("AIClassification", "transactionId", transactionId);
        }
        return AIClassificationResponse.from(classification);
    }

    /** Valida que a classificação pertence à transação de {@code userId}. */
    private boolean ownsClassification(AIClassifications classification, UUID userId) {
        Transactions tx = classification.getTransactions();
        return tx != null && tx.getUser() != null && tx.getUser().getId().equals(userId);
    }

    /**
     * Confirma ou corrige uma classificação de IA.
     *
     * <ul>
     *   <li>Valida ownership da classificação e da categoria de destino.</li>
     *   <li>Atualiza {@code ai_classifications} (confirmedCategory, wasConfirmed, wasCorrected).</li>
     *   <li>Atualiza {@code transactions.category_id} com a categoria confirmada.</li>
     *   <li>Reconcilia o consumo de orçamento: reverte a categoria anterior (se EXPENSE paga)
     *       e aplica a nova.</li>
     * </ul>
     */
    @Transactional
    public AIClassificationResponse confirmClassification(UUID userId, UUID classificationId, UUID confirmedCategoryId) {
        AIClassifications classification = classificationRepository.findById(classificationId)
                .orElseThrow(() -> new ResourceNotFoundException("AIClassification", "id", classificationId));

        if (!ownsClassification(classification, userId)) {
            throw new ResourceNotFoundException("AIClassification", "id", classificationId);
        }

        Categories confirmedCategory = categoryRepository.findById(confirmedCategoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", confirmedCategoryId));

        // Categoria deve ser do sistema ou do próprio usuário
        if (confirmedCategory.getUser() != null
                && !confirmedCategory.getUser().getId().equals(userId)) {
            throw new BadRequestException("Categoria não pertence a este usuário");
        }

        // O tipo da categoria deve ser compatível com o tipo da transação
        // (impede que uma despesa seja reclassificada para categoria de receita,
        // o que distorceria relatórios agrupados por tipo).
        Transactions txForType = classification.getTransactions();
        if (txForType != null && confirmedCategory.getType() != null
                && txForType.getType() != null
                && !confirmedCategory.getType().name().equals(txForType.getType().name())) {
            throw new BadRequestException(
                    "Tipo da categoria (" + confirmedCategory.getType()
                    + ") incompatível com o tipo da transação (" + txForType.getType() + ")");
        }

        // 1. Atualiza a classificação de IA
        Categories previous = classification.getConfirmedCategory();
        classification.setConfirmedCategory(confirmedCategory);
        classification.setWasConfirmed(true);
        classification.setConfirmedAt(Instant.now());

        if (classification.getSuggestedCategory() != null
                && !classification.getSuggestedCategory().getId().equals(confirmedCategoryId)) {
            classification.setWasCorrected(true);
        }

        classification = classificationRepository.save(classification);

        // 2. Atualiza a transação original e reconcilia o orçamento
        Transactions transaction = classification.getTransactions();
        if (transaction != null) {
            Categories oldTxCategory = transaction.getCategories();
            UUID oldTxCategoryId = oldTxCategory != null ? oldTxCategory.getId() : null;

            transaction.setCategories(confirmedCategory);
            transactionRepository.save(transaction);

            boolean countsForBudget = transaction.getType() == TransactionsType.EXPENSE
                    && Boolean.TRUE.equals(transaction.getIsPaid());
            if (countsForBudget && (oldTxCategoryId == null
                    || !oldTxCategoryId.equals(confirmedCategoryId))) {
                if (oldTxCategoryId != null) {
                    budgetService.applyTransactionDelta(userId, oldTxCategoryId,
                            transaction.getAmount().negate(), transaction.getTransactionDate());
                }
                budgetService.applyTransactionDelta(userId, confirmedCategoryId,
                        transaction.getAmount(), transaction.getTransactionDate());
            }
        }

        // Evita warning de variável não usada quando a classificação já tinha um confirmedCategory
        if (previous != null && !previous.getId().equals(confirmedCategoryId)) {
            classification.setWasCorrected(true);
        }

        return AIClassificationResponse.from(classification);
    }
}