package com.fyna.Fyna.core.features.ai.infrastructure;

import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.shared.domain.User;

/**
 * Scheduled job that triggers AI analysis for all active users.
 *
 * Runs daily at 3 AM. Each user gets:
 * - Pattern detection (spending anomalies, trends, recurring)
 * - Spending predictions for next month
 * - Investment recommendations update
 *
 * Enable with @EnableScheduling on your main application class.
 */
@Component
public class AIAnalysisScheduler {

    private static final Logger log = LoggerFactory.getLogger(AIAnalysisScheduler.class);

    private final AIEngineClient aiEngineClient;
    private final UserRepository userRepository;

    public AIAnalysisScheduler(AIEngineClient aiEngineClient, UserRepository userRepository) {
        this.aiEngineClient = aiEngineClient;
        this.userRepository = userRepository;
    }

    /**
     * Daily full analysis at 3:00 AM.
     */
    @Scheduled(cron = "0 0 3 * * *")
    public void dailyAnalysis() {
        if (!aiEngineClient.isHealthy()) {
            log.warn("AI engine is not healthy, skipping daily analysis");
            return;
        }

        log.info("Starting daily AI analysis for all users...");

        List<User> activeUsers = userRepository.findAll().stream()
                .filter(u -> "ACTIVE".equals(u.getStatus()))
                .toList();

        for (User user : activeUsers) {
            try {
                aiEngineClient.analyzeUser(user.getId());
            } catch (Exception e) {
                log.error("Failed to trigger analysis for user {}: {}", user.getId(), e.getMessage());
            }
        }

        log.info("Daily AI analysis triggered for {} users", activeUsers.size());
    }
}
