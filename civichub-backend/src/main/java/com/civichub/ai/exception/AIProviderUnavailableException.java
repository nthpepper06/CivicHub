package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class AIProviderUnavailableException extends AIException {

    public AIProviderUnavailableException(String provider) {
        super(
                "AI_PROVIDER_UNAVAILABLE",
                "Configured AI provider is not available: " + provider,
                HttpStatus.SERVICE_UNAVAILABLE);
    }
}
