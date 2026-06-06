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

import com.fasterxml.jackson.annotation.JsonAutoDetect;
import com.fasterxml.jackson.annotation.JsonTypeInfo;
import com.fasterxml.jackson.annotation.PropertyAccessor;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.jsontype.BasicPolymorphicTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;

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
                        buildRedisValueSerializer()));
    }

    /**
     * Serializador de valor para o cache.
     *
     * Por que builder em vez do construtor default:
     *   1. O default do {@code GenericJackson2JsonRedisSerializer} chama
     *      {@code mapper.writeValueAsBytes(value)} — Jackson então usa a classe
     *      concreta da {@code value} (ex.: {@code ArrayList}) como tipo declarado
     *      e NÃO emite type info na raiz.
     *   2. Com tipo declarado = {@code Object.class}, Jackson emite o wrapper
     *      {@code ["fqcn", payload]} também na raiz — sem isso, uma
     *      {@code List<CategoryResponse>} é desserializada como token inesperado
     *      ({@code Unexpected token START_ARRAY}) e levanta
     *      {@code SerializationException}.
     */
    private GenericJackson2JsonRedisSerializer buildRedisValueSerializer() {
        ObjectMapper mapper = buildRedisObjectMapper();
        return GenericJackson2JsonRedisSerializer.builder()
                .objectMapper(mapper)
                .writer((m, source) -> m.writerFor(Object.class).writeValueAsBytes(source))
                .reader((m, source, type) -> m.readerFor(Object.class).readValue(source))
                .build();
    }

    private ObjectMapper buildRedisObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.setVisibility(PropertyAccessor.ALL, JsonAutoDetect.Visibility.ANY);
        // WRAPPER_ARRAY é o único modo que tagueia containers JSON na raiz
        // (As.PROPERTY exige um objeto JSON para acomodar o campo @class).
        mapper.activateDefaultTyping(
                BasicPolymorphicTypeValidator.builder()
                        .allowIfBaseType(Object.class)
                        .build(),
                ObjectMapper.DefaultTyping.NON_FINAL,
                JsonTypeInfo.As.WRAPPER_ARRAY);
        return mapper;
    }
}
