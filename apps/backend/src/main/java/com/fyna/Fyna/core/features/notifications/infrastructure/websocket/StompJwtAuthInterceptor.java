package com.fyna.Fyna.core.features.notifications.infrastructure.websocket;

import java.security.Principal;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.lang.NonNull;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.stereotype.Component;

import com.fyna.Fyna.core.security.JwtTokenProvider;

/**
 * Valida o JWT no frame STOMP CONNECT e associa o {@link Principal} (userId) à
 * sessão. Spring então usa esse Principal para resolver mensagens enviadas via
 * {@code convertAndSendToUser(userId, ...)}.
 */
@Component
public class StompJwtAuthInterceptor implements ChannelInterceptor {

    private static final Logger log = LoggerFactory.getLogger(StompJwtAuthInterceptor.class);
    private static final String BEARER_PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;

    public StompJwtAuthInterceptor(JwtTokenProvider jwtTokenProvider) {
        this.jwtTokenProvider = jwtTokenProvider;
    }

    @Override
    public Message<?> preSend(@NonNull Message<?> message, @NonNull MessageChannel channel) {
        StompHeaderAccessor accessor = MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);
        if (accessor == null || !StompCommand.CONNECT.equals(accessor.getCommand())) {
            return message;
        }

        String authHeader = accessor.getFirstNativeHeader("Authorization");
        if (authHeader == null || !authHeader.startsWith(BEARER_PREFIX)) {
            log.warn("STOMP CONNECT sem Authorization válida — recusando");
            return null; // recusa o CONNECT
        }

        try {
            String token = authHeader.substring(BEARER_PREFIX.length());
            UUID userId = jwtTokenProvider.getUserIdFromToken(token);
            accessor.setUser(new StompUserPrincipal(userId));
            log.debug("STOMP CONNECT autenticado para user {}", userId);
        } catch (Exception e) {
            log.warn("STOMP CONNECT com token inválido: {}", e.getMessage());
            return null;
        }
        return message;
    }

    /** Principal mínimo cujo {@link #getName()} é o userId — usado para resolver destinos /user/. */
    public static final class StompUserPrincipal implements Principal {
        private final String name;

        public StompUserPrincipal(UUID userId) {
            this.name = userId.toString();
        }

        @Override
        public String getName() {
            return name;
        }
    }
}
