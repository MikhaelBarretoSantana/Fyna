package com.fyna.Fyna.core.security;

import java.util.UUID;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class SecurityUtils {

    public UUID getCurrentUserId() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal)) {
            throw new com.fyna.Fyna.core.exception.UnauthorizedException("Usuário não autenticado");
        }
        return ((UserPrincipal) authentication.getPrincipal()).getId();
    }

    public UserPrincipal getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof UserPrincipal)) {
            throw new com.fyna.Fyna.core.exception.UnauthorizedException("Usuário não autenticado");
        }
        return (UserPrincipal) authentication.getPrincipal();
    }
}
