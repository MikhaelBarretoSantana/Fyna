package com.fyna.Fyna.core.features.ai.infrastructure;

import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatusCode;
import org.springframework.retry.annotation.Backoff;
import org.springframework.retry.annotation.Recover;
import org.springframework.retry.annotation.Retryable;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestTemplate;

/**
 * Encapsula as chamadas HTTP ao microserviço de IA com política de retry
 * com backoff exponencial.
 *
 * Política (definida pela anotação @Retryable):
 *   - Tentativas:   3 totais (1 inicial + 2 retries)
 *   - Backoff:      500ms inicial, multiplicador 2.0 (500ms -> 1s -> 2s)
 *   - Disparo:      apenas ResourceAccessException (timeout/conexão recusada)
 *                   e HttpServerErrorException (HTTP 5xx).
 *   - Não-disparo:  4xx (erro do cliente — não adianta tentar de novo).
 *
 * O retry é isolado nesta classe para que o circuit breaker e a anotação
 * @Async permaneçam no AIEngineClient sem interferência mútua entre proxies.
 * Quando todas as tentativas falham, o método @Recover é invocado e propaga
 * a exceção para o chamador, que registra a falha no circuit breaker.
 */
@Component
public class AIEngineRestCaller {

    private static final Logger log = LoggerFactory.getLogger(AIEngineRestCaller.class);

    private final RestTemplate restTemplate;

    public AIEngineRestCaller(RestTemplate aiRestTemplate) {
        this.restTemplate = aiRestTemplate;
    }

    @Retryable(
            retryFor = { ResourceAccessException.class, HttpServerErrorException.class },
            maxAttempts = 3,
            backoff = @Backoff(delay = 500, multiplier = 2.0, maxDelay = 4000)
    )
    public void post(String url, Map<String, Object> body) {
        restTemplate.postForEntity(url, body, Map.class);
    }

    @Recover
    public void recover(ResourceAccessException ex, String url, Map<String, Object> body) {
        log.warn("AI engine indisponivel apos retries (rede/timeout) [{}]: {}", url, ex.getMessage());
        throw ex;
    }

    @Recover
    public void recover(HttpServerErrorException ex, String url, Map<String, Object> body) {
        HttpStatusCode status = ex.getStatusCode();
        log.warn("AI engine retornou {} apos retries [{}]", status, url);
        throw ex;
    }
}
