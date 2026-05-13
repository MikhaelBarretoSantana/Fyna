package com.fyna.Fyna.core.security;

import java.util.Collection;
import java.util.Collections;
import java.util.UUID;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.fyna.Fyna.core.shared.domain.User;

public class UserPrincipal implements UserDetails {

    private static final long serialVersionUID = 1L;

    private final UUID id;
    private final String login;
    private final String email;
    private final String password;
    private final boolean active;

    public UserPrincipal(UUID id, String login, String email, String password, boolean active) {
        this.id = id;
        this.login = login;
        this.email = email;
        this.password = password;
        this.active = active;
    }

    public static UserPrincipal from(User user) {
        return new UserPrincipal(
                user.getId(),
                user.getLogin(),
                user.getEmail(),
                user.getPassword(),
                user.getStatus() == com.fyna.Fyna.core.shared.enums.UserStatus.ACTIVE
        );
    }

    public UUID getId() {
        return id;
    }

    public String getLogin() {
        return login;
    }

    public String getEmail() {
        return email;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.emptyList();
    }

    @Override
    public String getPassword() {
        return password;
    }

    @Override
    public String getUsername() {
        return login;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return active;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return active;
    }
}
