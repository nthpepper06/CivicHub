package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class UnsupportedAIProviderException extends AIException {

    public UnsupportedAIProviderException(String provider) {
        super(
                "AI_UNSUPPORTED_PROVIDER",
                "Configured AI provider is not supported: " + provider,
                HttpStatus.BAD_REQUEST);
    }
}
