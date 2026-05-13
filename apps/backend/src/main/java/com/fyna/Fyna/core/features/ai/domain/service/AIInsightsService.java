package com.fyna.Fyna.core.features.ai.domain.service;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.ai.data.repository.AIClassificationRepository;
import com.fyna.Fyna.core.features.ai.data.repository.InvestmentRecommendationRepository;
import com.fyna.Fyna.core.features.ai.data.repository.SpendingPatternRepository;
import com.fyna.Fyna.core.features.ai.data.repository.SpendingPredictionRepository;
import com.fyna.Fyna.core.features.ai.presentation.dto.AIClassificationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.InvestmentRecommendationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPatternResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPredictionResponse;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.shared.domain.AIClassifications;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.InvestmentRecommendation;
import com.fyna.Fyna.core.shared.domain.Transactions;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.SpendingPatternType;

@Service
public class AIInsightsService {

    private final InvestmentRecommendationRepository recommendationRepository;
    private final SpendingPredictionRepository predictionRepository;
    private final SpendingPatternRepository patternRepository;
    private final AIClassificationRepository classificationRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;

    public AIInsightsService(InvestmentRecommendationRepository recommendationRepository,
            SpendingPredictionRepository predictionRepository, SpendingPatternRepository patternRepository,
            AIClassificationRepository classificationRepository, CategoryRepository categoryRepository,
            TransactionRepository transactionRepository) {
        this.recommendationRepository = recommendationRepository;
        this.predictionRepository = predictionRepository;
        this.patternRepository = patternRepository;
        this.classificationRepository = classificationRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
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
    public AIClassificationResponse getClassificationByTransaction(UUID transactionId) {
        AIClassifications classification = classificationRepository.findByTransactionsId(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("AIClassification", "transactionId", transactionId));
        return AIClassificationResponse.from(classification);
    }

    /**
     * Confirma ou corrige uma classificação de IA.
     * - Atualiza ai_classifications (confirmedCategory, wasConfirmed, wasCorrected)
     * - TAMBÉM atualiza transactions.category_id com a categoria confirmada
     */
    @Transactional
    public AIClassificationResponse confirmClassification(UUID classificationId, UUID confirmedCategoryId) {
        AIClassifications classification = classificationRepository.findById(classificationId)
                .orElseThrow(() -> new ResourceNotFoundException("AIClassification", "id", classificationId));

        Categories confirmedCategory = categoryRepository.findById(confirmedCategoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", confirmedCategoryId));

        // 1. Atualiza a classificação de IA
        classification.setConfirmedCategory(confirmedCategory);
        classification.setWasConfirmed(true);
        classification.setConfirmedAt(Instant.now());

        if (classification.getSuggestedCategory() != null
                && !classification.getSuggestedCategory().getId().equals(confirmedCategoryId)) {
            classification.setWasCorrected(true);
        }

        classification = classificationRepository.save(classification);

        // 2. Atualiza a transação original com a categoria confirmada
        Transactions transaction = classification.getTransactions();
        if (transaction != null) {
            transaction.setCategories(confirmedCategory);
            transactionRepository.save(transaction);
        }

        return AIClassificationResponse.from(classification);
    }
}