package com.fyna.Fyna.core.config;

import java.time.Duration;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

/**
 * Configuração do cache distribuído via Redis.
 *
 * Caches usados pelo núcleo transacional:
 *   - "system-categories":   lista global de categorias do sistema (read-mostly).
 *   - "category-by-type":    categorias filtradas por (userId, tipo).
 *
 * Política de invalidação:
 *   - TTL fixo (1h para system-categories, 10min para listas por usuário/tipo).
 *   - Invalidação explícita via @CacheEvict nos métodos de create/update/delete.
 *
 * Em caso de indisponibilidade do Redis, o Spring Cache faz fallback transparente:
 * o cache é simplesmente ignorado e cada chamada bate no PostgreSQL.
 */
@Configuration
@EnableCaching
public class RedisCacheConfig {

    private static final Duration SYSTEM_CATEGORIES_TTL = Duration.ofHours(1);
    private static final Duration USER_SCOPED_TTL = Duration.ofMinutes(10);

    @Bean
    public RedisCacheManager cacheManager(RedisConnectionFactory connectionFactory) {
        RedisCacheConfiguration defaultConfig = baseConfig(USER_SCOPED_TTL);

        return RedisCacheManager.builder(connectionFactory)
                .cacheDefaults(defaultConfig)
                .withCacheConfiguration("system-categories", baseConfig(SYSTEM_CATEGORIES_TTL))
                .withCacheConfiguration("category-by-type", baseConfig(USER_SCOPED_TTL))
                .transactionAware()
                .build();
    }

    private RedisCacheConfiguration baseConfig(Duration ttl) {
        return RedisCacheConfiguration.defaultCacheConfig()
                .entryTtl(ttl)
                .disableCachingNullValues()
                .prefixCacheNameWith("fyna::")
                .serializeKeysWith(RedisSerializationContext.SerializationPair.fromSerializer(
                        new StringRedisSerializer()))
                .serializeValuesWith(RedisSerializationContext.SerializationPair.fromSerializer(
                        new GenericJackson2JsonRedisSerializer()));
    }
}
