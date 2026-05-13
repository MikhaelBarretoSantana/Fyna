package com.fyna.Fyna.core.features.ai.infrastructure;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

/**
 * REST client that communicates with the Python AI microservice (fyna-ai-engine).
 *
 * All calls are fire-and-forget (@Async) so they never block the main request.
 * Built-in circuit breaker: após N falhas consecutivas, abre o circuito por
 * `circuitOpenSeconds` segundos antes de tentar novamente (half-open).
 *
 * Configuração (application.yml):
 *   fyna.ai.circuit-breaker.failure-threshold=5
 *   fyna.ai.circuit-breaker.open-seconds=60
 */
@Service
public class AIEngineClient {

    private static final Logger log = LoggerFactory.getLogger(AIEngineClient.class);

    private final RestTemplate restTemplate;
    private final AIEngineConfig config;

    @Value("${fyna.ai.circuit-breaker.failure-threshold:5}")
    private int failureThreshold;

    @Value("${fyna.ai.circuit-breaker.open-seconds:60}")
    private long circuitOpenSeconds;

    // Circuit breaker state
    private final AtomicInteger consecutiveFailures = new AtomicInteger(0);
    private final AtomicReference<Instant> openedAt = new AtomicReference<>(null);

    public AIEngineClient(RestTemplate aiRestTemplate, AIEngineConfig config) {
        this.restTemplate = aiRestTemplate;
        this.config = config;
    }

    @Async
    public void classifyTransaction(UUID transactionId, UUID userId, String description,
                                     BigDecimal amount, String transactionType) {
        if (!isCircuitClosed()) return;

        try {
            String url = config.getEngineUrl() + "/api/v1/ai-engine/classify";
            Map<String, Object> body = Map.of(
                "transaction_id", transactionId.toString(),
                "user_id", userId.toString(),
                "description", description,
                "amount", amount,
                "transaction_type", transactionType
            );
            restTemplate.postForEntity(url, body, Map.class);
            onSuccess();
            log.info("Classification requested for transaction {}", transactionId);
        } catch (Exception e) {
            onFailure("classify", e);
        }
    }

    @Async
    public void analyzeUser(UUID userId) {
        if (!isCircuitClosed()) return;

        try {
            String url = config.getEngineUrl() + "/api/v1/ai-engine/analyze";
            restTemplate.postForEntity(url, Map.of("user_id", userId.toString()), Map.class);
            onSuccess();
            log.info("Full analysis requested for user {}", userId);
        } catch (Exception e) {
            onFailure("analyze", e);
        }
    }

    @Async
    public void predictSpending(UUID userId, LocalDate targetMonth) {
        if (!isCircuitClosed()) return;

        try {
            String url = config.getEngineUrl() + "/api/v1/ai-engine/predict";
            Map<String, Object> body = Map.of(
                "user_id", userId.toString(),
                "target_month", targetMonth.toString()
            );
            restTemplate.postForEntity(url, body, Map.class);
            onSuccess();
            log.info("Prediction requested for user {} month {}", userId, targetMonth);
        } catch (Exception e) {
            onFailure("predict", e);
        }
    }

    @Async
    public void generateRecommendations(UUID userId) {
        if (!isCircuitClosed()) return;

        try {
            String url = config.getEngineUrl() + "/api/v1/ai-engine/recommend";
            restTemplate.postForEntity(url, Map.of("user_id", userId.toString()), Map.class);
            onSuccess();
            log.info("Recommendations requested for user {}", userId);
        } catch (Exception e) {
            onFailure("recommend", e);
        }
    }

    public boolean isHealthy() {
        try {
            String url = config.getEngineUrl() + "/api/v1/ai-engine/health";
            var response = restTemplate.getForEntity(url, Map.class);
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            return false;
        }
    }

    // ─── Circuit breaker helpers ────────────────────────────────────────

    private boolean isCircuitClosed() {
        Instant opened = openedAt.get();
        if (opened == null) return true;

        if (Instant.now().isAfter(opened.plusSeconds(circuitOpenSeconds))) {
            // Half-open: tenta uma requisição
            log.info("AI circuit breaker entrando em half-open");
            return true;
        }

        log.warn("AI circuit breaker ABERTO — ignorando chamada ao microserviço");
        return false;
    }

    private void onSuccess() {
        consecutiveFailures.set(0);
        openedAt.set(null);
    }

    private void onFailure(String operation, Exception e) {
        int failures = consecutiveFailures.incrementAndGet();
        log.warn("AI engine falhou em '{}' ({}/{}): {}", operation, failures, failureThreshold, e.getMessage());

        if (failures >= failureThreshold) {
            openedAt.compareAndSet(null, Instant.now());
            log.error("AI circuit breaker ABERTO após {} falhas consecutivas", failures);
        }
    }
}
