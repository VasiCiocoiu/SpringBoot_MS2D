package com.ruche.ruchesconnectespringboot.firebase;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @Value("${firebase.database-url}")
    private String dbUrl;

    @Value("${firebase.credentials.classpath}")
    private String credsPath;

    @Bean
    public DatabaseReference firebaseRootRef() throws Exception {
        // 1) charge le service account du PROJET de ta RTDB
        InputStream in = getClass().getResourceAsStream(credsPath);
        if (in == null) {
            throw new IllegalStateException("Service account introuvable dans le classpath: " + credsPath);
        }

        FirebaseOptions opts = FirebaseOptions.builder()
                .setCredentials(GoogleCredentials.fromStream(in))   // ← SERVICE ACCOUNT
                .setDatabaseUrl(dbUrl)                              // ← URL EXACTE de ta RTDB
                .build();

        if (FirebaseApp.getApps().isEmpty()) {
            FirebaseApp.initializeApp(opts);
        }
        DatabaseReference ref = FirebaseDatabase.getInstance().getReference();
        System.out.println("[Firebase] DB URL        = " + dbUrl);
        System.out.println("[Firebase] Root ref      = " + ref);
        System.out.println("[Firebase] App name      = " + FirebaseApp.getInstance().getName());
        return ref;
    }
}
