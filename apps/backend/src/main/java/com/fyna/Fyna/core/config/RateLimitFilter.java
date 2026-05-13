package com.fyna.Fyna.core.config;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Rate limiter simples (in-memory) para proteger endpoints de autenticação.
 *
 * Configurável via application.yml:
 *   fyna.rate-limit.auth.max-requests=10
 *   fyna.rate-limit.auth.window-seconds=60
 */
@Component
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);

    @Value("${fyna.rate-limit.auth.max-requests:10}")
    private int maxRequests;

    @Value("${fyna.rate-limit.auth.window-seconds:60}")
    private long windowSeconds;

    // IP -> [count, windowStartEpochSecond]
    private final Map<String, long[]> buckets = new ConcurrentHashMap<>();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getServletPath();
        // Só limita os endpoints sensíveis de autenticação
        return !path.startsWith("/api/v1/auth/login")
            && !path.startsWith("/api/v1/auth/register")
            && !path.startsWith("/api/v1/auth/refresh");
    }

    @Override
    protected void doFilterInternal(
        HttpServletRequest request,
        HttpServletResponse response,
        FilterChain filterChain
    ) throws ServletException, IOException {

        String ip = resolveClientIp(request);
        long now = Instant.now().getEpochSecond();

        long[] bucket = buckets.compute(ip, (key, existing) -> {
            if (existing == null || now - existing[1] >= windowSeconds) {
                // Nova janela
                return new long[]{1, now};
            }
            existing[0]++;
            return existing;
        });

        long count = bucket[0];

        if (count > maxRequests) {
            log.warn("Rate limit excedido para IP {} em {}", ip, request.getServletPath());
            response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
            response.setContentType(MediaType.APPLICATION_JSON_VALUE);
            response.getWriter().write(
                "{\"success\":false,\"message\":\"Muitas tentativas. Aguarde antes de tentar novamente.\"}");
            return;
        }

        filterChain.doFilter(request, response);
    }

    private String resolveClientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            // Pega o primeiro IP da cadeia de proxies
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
