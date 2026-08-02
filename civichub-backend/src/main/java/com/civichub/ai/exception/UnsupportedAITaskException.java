package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class UnsupportedAITaskException extends AIException {

    public UnsupportedAITaskException(String taskType) {
        super("AI_UNSUPPORTED_TASK", "Unsupported AI task", HttpStatus.BAD_REQUEST);
    }
}
