package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class PromptTemplateDisabledException extends AIException {

    public PromptTemplateDisabledException(String template) {
        super("AI_PROMPT_TEMPLATE_DISABLED", "Prompt template is disabled", HttpStatus.FORBIDDEN);
    }
}
