package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class PromptRenderingException extends AIException {

    public PromptRenderingException(String message) {
        super("AI_PROMPT_RENDERING_FAILED", message, HttpStatus.BAD_REQUEST);
    }
}
