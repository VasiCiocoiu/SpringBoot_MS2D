// src/main/java/com/ruche/ruchesconnectespringboot/security/FirebaseAuthRestService.java
package com.ruche.ruchesconnectespringboot.security;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class FirebaseAuthRestService {

    private final String apiKey;
    private final RestTemplate http = new RestTemplate();

    public FirebaseAuthRestService(@Value("${firebase.apiKey}") String apiKey) {
        this.apiKey = apiKey;
    }

    public SignInResponse signInWithPassword(String email, String password) {
        String url = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=" + apiKey;

        SignInRequest req = new SignInRequest(email, password, true);
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<SignInRequest> entity = new HttpEntity<>(req, headers);

        ResponseEntity<SignInResponse> resp =
                http.postForEntity(url, entity, SignInResponse.class);

        return resp.getBody(); // contient notamment localId (UID) et idToken
    }

    // --- DTOs ---
    public record SignInRequest(String email, String password, boolean returnSecureToken) {}
    public static class SignInResponse {
        public String localId;   // = UID
        public String email;

    }
}
