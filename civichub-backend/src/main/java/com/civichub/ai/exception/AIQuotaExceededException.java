package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class AIQuotaExceededException extends AIException {

    public AIQuotaExceededException() {
        super("AI_QUOTA_EXCEEDED", "AI provider quota has been exceeded", HttpStatus.TOO_MANY_REQUESTS);
    }
}
