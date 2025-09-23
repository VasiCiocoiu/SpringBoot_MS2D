package com.ruche.ruchesconnectespringboot.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.*;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    private final AuthenticationProvider firebaseProvider;
    private final String successUrl;

    public SecurityConfig(FirebaseAuthenticationProvider firebaseProvider,
                          @Value("${app.login.success-url:/user/rucher}") String successUrl) {
        this.firebaseProvider = firebaseProvider;
        this.successUrl = successUrl;
    }

    @Bean
    public AuthenticationManager authenticationManager() {
        return new ProviderManager(firebaseProvider);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable) 
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/css/**", "/login").permitAll()
                        .anyRequest().authenticated()
                )
                .formLogin(form -> form
                        .loginPage("/login")               // ta page thymeleaf GET
                        .loginProcessingUrl("/login")      // POST du formulaire
                        .defaultSuccessUrl(successUrl, true)
                        .failureUrl("/login?error")
                        .permitAll()
                )
                .logout(logout -> logout
                        .logoutUrl("/logout")
                        .logoutSuccessUrl("/login?logout")
                )
                .authenticationManager(authenticationManager());

        return http.build();
    }
}
