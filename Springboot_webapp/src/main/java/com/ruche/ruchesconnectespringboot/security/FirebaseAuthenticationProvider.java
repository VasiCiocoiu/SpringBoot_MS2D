// src/main/java/com/ruche/ruchesconnectespringboot/security/FirebaseAuthenticationProvider.java
package com.ruche.ruchesconnectespringboot.security;

import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.stereotype.Component;

@Component
public class FirebaseAuthenticationProvider implements AuthenticationProvider {

    private final FirebaseAuthRestService auth;

    public FirebaseAuthenticationProvider(FirebaseAuthRestService auth) {
        this.auth = auth;
    }

    @Override
    public Authentication authenticate(Authentication authentication) throws AuthenticationException {
        String email = (String) authentication.getPrincipal();
        String password = (String) authentication.getCredentials();

        try {
            var resp = auth.signInWithPassword(email, password);
            if (resp == null || resp.localId == null) {
                throw new BadCredentialsException("Firebase Auth failed");
            }
            FirebaseUser user = new FirebaseUser(resp.localId, resp.email);
            // On renvoie un token authentifié avec notre principal (qui porte l’UID)
            return new UsernamePasswordAuthenticationToken(user, null, user.getAuthorities());
        } catch (Exception e) {
            throw new BadCredentialsException("Invalid credentials", e);
        }
    }

    @Override
    public boolean supports(Class<?> authentication) {
        return UsernamePasswordAuthenticationToken.class.isAssignableFrom(authentication);
    }
}
