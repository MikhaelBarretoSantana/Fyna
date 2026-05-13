package com.fyna.Fyna.core.features.ai.infrastructure;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.web.client.RestTemplate;

/**
 * Configuration for the Python AI microservice connection.
 *
 * application.yml:
 *   fyna:
 *     ai:
 *       engine-url: http://localhost:8081
 *       internal-api-key: ${FYNA_AI_INTERNAL_KEY}   # deve coincidir com FYNA_AI_INTERNAL_API_KEY no Python
 */
@Configuration
public class AIEngineConfig {

    @Value("${fyna.ai.engine-url:http://localhost:8081}")
    private String engineUrl;

    @Value("${fyna.ai.internal-api-key:dev-insecure-key-change-in-prod}")
    private String internalApiKey;

    @Bean
    public RestTemplate aiRestTemplate() {
        RestTemplate template = new RestTemplate();
        // Injeta a API key em todos os requests ao microserviço
        ClientHttpRequestInterceptor apiKeyInterceptor = (request, body, execution) -> {
            request.getHeaders().set("X-Internal-Key", internalApiKey);
            return execution.execute(request, body);
        };
        template.setInterceptors(List.of(apiKeyInterceptor));
        return template;
    }

    public String getEngineUrl() {
        return engineUrl;
    }
}
