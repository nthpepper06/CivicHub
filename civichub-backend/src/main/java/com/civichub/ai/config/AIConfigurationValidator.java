package com.civichub.ai.config;

import com.civichub.ai.model.AIProviderType;
import com.civichub.ai.task.AITaskType;
import jakarta.annotation.PostConstruct;
import java.time.Duration;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
@RequiredArgsConstructor
public class AIConfigurationValidator {

    private final AIProperties properties;

    @PostConstruct
    public void validate() {
        if (!Boolean.TRUE.equals(properties.getEnabled())) {
            return;
        }
        AIProviderType provider = AIProviderType.from(properties.getProvider())
                .orElseThrow(() -> new IllegalStateException("Unsupported AI provider: " + properties.getProvider()));
        if (provider == AIProviderType.OPENAI) {
            requireText(properties.getApiKey(), "OpenAI API key is required when OpenAI provider is enabled");
        }
        requireText(properties.getModel(), "AI model is required");
        requireRange(properties.getTemperature(), 0.0, 2.0, "AI temperature must be between 0 and 2");
        requirePositive(properties.getMaxTokens(), "AI max tokens must be positive");
        requirePositive(properties.getRetryMaxAttempts(), "AI retry max attempts must be positive");
        requirePositive(properties.getRateLimitRequests(), "AI rate limit requests must be positive");
        requirePositive(properties.getTimeout(), "AI timeout must be positive");
        requirePositive(properties.getRetryBackoff(), "AI retry backoff must be positive");
        requirePositive(properties.getRateLimitWindow(), "AI rate limit window must be positive");
        requireNonNegative(properties.getInputTokenCostPerThousand(), "AI input token cost must be non-negative");
        requireNonNegative(properties.getOutputTokenCostPerThousand(), "AI output token cost must be non-negative");
        properties.getTasks().forEach((taskName, task) -> {
            try {
                AITaskType.valueOf(taskName);
            } catch (IllegalArgumentException exception) {
                throw new IllegalStateException("Unsupported AI task override: " + taskName, exception);
            }
            if (task.getTemperature() != null) {
                requireRange(task.getTemperature(), 0.0, 2.0, "AI task temperature must be between 0 and 2");
            }
            if (task.getMaxTokens() != null) {
                requirePositive(task.getMaxTokens(), "AI task max tokens must be positive");
            }
        });
    }

    private void requireText(String value, String message) {
        if (!StringUtils.hasText(value)) {
            throw new IllegalStateException(message);
        }
    }

    private void requireRange(Double value, double min, double max, String message) {
        if (value == null || value < min || value > max) {
            throw new IllegalStateException(message);
        }
    }

    private void requirePositive(Integer value, String message) {
        if (value == null || value <= 0) {
            throw new IllegalStateException(message);
        }
    }

    private void requirePositive(Duration value, String message) {
        if (value == null || value.isZero() || value.isNegative()) {
            throw new IllegalStateException(message);
        }
    }

    private void requireNonNegative(Double value, String message) {
        if (value == null || value < 0) {
            throw new IllegalStateException(message);
        }
    }
}
