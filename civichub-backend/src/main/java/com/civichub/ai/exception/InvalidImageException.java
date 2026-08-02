package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class InvalidImageException extends AIException {

    public InvalidImageException(String message) {
        super("AI_INVALID_IMAGE", message, HttpStatus.BAD_REQUEST);
    }
}
