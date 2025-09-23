
package com.ruche.ruchesconnectespringboot.security;

import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

public class FirebaseUser implements UserDetails {
    @Getter
    private final String uid;
    private final String email;

    public FirebaseUser(String uid, String email) {
        this.uid = uid;
        this.email = email;
    }

    public String getEmailAddress() { return email; }

    @Override public Collection<? extends GrantedAuthority> getAuthorities() { return List.of(); }
    @Override public String getPassword() { return ""; }
    @Override public String getUsername() { return email; }
    @Override public boolean isAccountNonExpired() { return true; }
    @Override public boolean isAccountNonLocked() { return true; }
    @Override public boolean isCredentialsNonExpired() { return true; }
    @Override public boolean isEnabled() { return true; }
}
