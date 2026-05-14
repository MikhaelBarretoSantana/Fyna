package com.fyna.Fyna.core.features.notifications.infrastructure.fcm;

import java.io.FileInputStream;
import java.io.IOException;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;

import jakarta.annotation.Nullable;

/**
 * Inicializa o Firebase Admin SDK quando uma credencial é fornecida via
 * {@code fyna.firebase.credentials-path}. Sem credenciais válidas, o bean
 * {@link FirebaseMessaging} fica como {@code null} e o {@link FcmSender}
 * vira no-op — o app continua subindo normalmente em ambientes locais ou de CI.
 */
@Configuration
public class FirebaseConfig {

    private static final Logger log = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${fyna.firebase.credentials-path:}")
    private String credentialsPath;

    @Bean
    @Nullable
    public FirebaseMessaging firebaseMessaging() {
        if (credentialsPath == null || credentialsPath.isBlank()) {
            log.info("Firebase desabilitado — fyna.firebase.credentials-path não configurado. Push notifications inativas.");
            return null;
        }

        try (FileInputStream serviceAccount = new FileInputStream(credentialsPath)) {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();
            FirebaseApp app = FirebaseApp.getApps().isEmpty()
                    ? FirebaseApp.initializeApp(options)
                    : FirebaseApp.getInstance();
            log.info("Firebase inicializado com credenciais de {}", credentialsPath);
            return FirebaseMessaging.getInstance(app);
        } catch (IOException e) {
            log.warn("Falha ao carregar credenciais Firebase em {}: {}. Push notifications inativas.",
                    credentialsPath, e.getMessage());
            return null;
        }
    }
}
