package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class StructuredOutputDefinitionException extends AIException {

    public StructuredOutputDefinitionException(String message) {
        super("AI_STRUCTURED_OUTPUT_DEFINITION_INVALID", message, HttpStatus.BAD_REQUEST);
    }
}
