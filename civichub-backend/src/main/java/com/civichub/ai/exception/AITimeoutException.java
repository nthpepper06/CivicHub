package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class AITimeoutException extends AIException {

    public AITimeoutException() {
        super("AI_TIMEOUT", "AI provider request timed out", HttpStatus.GATEWAY_TIMEOUT);
    }
}
