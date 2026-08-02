package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class PromptTemplateNotFoundException extends AIException {

    public PromptTemplateNotFoundException(String template) {
        super("AI_PROMPT_TEMPLATE_NOT_FOUND", "Prompt template was not found", HttpStatus.BAD_REQUEST);
    }
}
