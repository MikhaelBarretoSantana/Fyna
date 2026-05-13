package com.fyna.Fyna.core.features.ai.presentation.resource;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.ai.domain.service.AIInsightsService;
import com.fyna.Fyna.core.features.ai.infrastructure.AIEngineClient;
import com.fyna.Fyna.core.features.ai.presentation.dto.AIClassificationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.ConfirmClassificationRequest;
import com.fyna.Fyna.core.features.ai.presentation.dto.InvestmentRecommendationResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPatternResponse;
import com.fyna.Fyna.core.features.ai.presentation.dto.SpendingPredictionResponse;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;
import com.fyna.Fyna.core.shared.dto.PageResponse;
import com.fyna.Fyna.core.shared.enums.SpendingPatternType;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/ai")
public class AIInsightsResource {

    private final AIInsightsService aiInsightsService;
    private final AIEngineClient aiEngineClient;
    private final SecurityUtils securityUtils;

    public AIInsightsResource(AIInsightsService aiInsightsService, AIEngineClient aiEngineClient,
            SecurityUtils securityUtils) {
        this.aiInsightsService = aiInsightsService;
        this.aiEngineClient = aiEngineClient;
        this.securityUtils = securityUtils;
    }

    // ================= Trigger Analysis (calls Python) =================

    /**
     * Trigger full AI analysis on demand.
     * Called from Flutter when user opens AI Insights or Planning page.
     * Fire-and-forget: returns immediately, analysis runs async.
     */
    @PostMapping("/analyze")
    public ResponseEntity<ApiResponse<Map<String, String>>> triggerAnalysis() {
        UUID userId = securityUtils.getCurrentUserId();
        aiEngineClient.analyzeUser(userId);
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "status", "analysis_triggered",
                "message", "Análise de IA iniciada. Os resultados estarão disponíveis em breve."
        )));
    }

    /**
     * Check if AI engine is healthy.
     */
    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Map<String, Object>>> aiHealth() {
        boolean healthy = aiEngineClient.isHealthy();
        return ResponseEntity.ok(ApiResponse.ok(Map.of(
                "ai_engine_healthy", healthy,
                "message", healthy ? "AI engine is running" : "AI engine is unavailable"
        )));
    }

    // ================= Investment Recommendations =================

    @GetMapping("/recommendations")
    public ResponseEntity<ApiResponse<PageResponse<InvestmentRecommendationResponse>>> getRecommendations(
            @PageableDefault(size = 10) Pageable pageable) {
        PageResponse<InvestmentRecommendationResponse> response =
                aiInsightsService.getRecommendations(securityUtils.getCurrentUserId(), pageable);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/recommendations/unviewed")
    public ResponseEntity<ApiResponse<List<InvestmentRecommendationResponse>>> getUnviewedRecommendations() {
        List<InvestmentRecommendationResponse> response =
                aiInsightsService.getUnviewedRecommendations(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/recommendations/{id}/view")
    public ResponseEntity<ApiResponse<InvestmentRecommendationResponse>> markAsViewed(@PathVariable UUID id) {
        InvestmentRecommendationResponse response =
                aiInsightsService.markRecommendationAsViewed(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PatchMapping("/recommendations/{id}/follow")
    public ResponseEntity<ApiResponse<InvestmentRecommendationResponse>> markAsFollowed(@PathVariable UUID id) {
        InvestmentRecommendationResponse response =
                aiInsightsService.markRecommendationAsFollowed(id, securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    // ================= Spending Predictions =================

    @GetMapping("/predictions")
    public ResponseEntity<ApiResponse<List<SpendingPredictionResponse>>> getPredictions(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) UUID categoryId) {
        UUID userId = securityUtils.getCurrentUserId();
        List<SpendingPredictionResponse> response;

        if (categoryId != null) {
            response = aiInsightsService.getPredictionsByCategory(userId, categoryId);
        } else if (startDate != null && endDate != null) {
            response = aiInsightsService.getPredictionsByDateRange(userId, startDate, endDate);
        } else {
            response = aiInsightsService.getPredictions(userId);
        }

        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    // ================= Spending Patterns =================

    @GetMapping("/patterns")
    public ResponseEntity<ApiResponse<List<SpendingPatternResponse>>> getPatterns(
            @RequestParam(required = false) SpendingPatternType type) {
        UUID userId = securityUtils.getCurrentUserId();
        List<SpendingPatternResponse> response = type != null
                ? aiInsightsService.getPatternsByType(userId, type)
                : aiInsightsService.getActivePatterns(userId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    // ================= AI Classifications =================

    @GetMapping("/classifications/pending")
    public ResponseEntity<ApiResponse<List<AIClassificationResponse>>> getPendingClassifications() {
        List<AIClassificationResponse> response =
                aiInsightsService.getPendingClassifications(securityUtils.getCurrentUserId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @GetMapping("/classifications/transaction/{transactionId}")
    public ResponseEntity<ApiResponse<AIClassificationResponse>> getClassificationByTransaction(
            @PathVariable UUID transactionId) {
        AIClassificationResponse response = aiInsightsService.getClassificationByTransaction(transactionId);
        return ResponseEntity.ok(ApiResponse.ok(response));
    }

    @PostMapping("/classifications/{id}/confirm")
    public ResponseEntity<ApiResponse<AIClassificationResponse>> confirmClassification(
            @PathVariable UUID id, @Valid @RequestBody ConfirmClassificationRequest request) {
        AIClassificationResponse response =
                aiInsightsService.confirmClassification(id, request.confirmedCategoryId());
        return ResponseEntity.ok(ApiResponse.ok(response));
    }
}
