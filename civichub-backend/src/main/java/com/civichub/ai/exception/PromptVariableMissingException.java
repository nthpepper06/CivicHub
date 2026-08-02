package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class PromptVariableMissingException extends AIException {

    public PromptVariableMissingException(String variableName) {
        super("AI_PROMPT_VARIABLE_MISSING", "Required prompt variable is missing", HttpStatus.BAD_REQUEST);
    }
}
