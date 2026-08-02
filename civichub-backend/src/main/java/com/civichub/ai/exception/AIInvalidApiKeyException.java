package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class AIInvalidApiKeyException extends AIException {

    public AIInvalidApiKeyException() {
        super("AI_INVALID_API_KEY", "AI provider authentication failed", HttpStatus.UNAUTHORIZED);
    }
}
