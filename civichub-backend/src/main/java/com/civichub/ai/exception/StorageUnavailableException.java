package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class StorageUnavailableException extends AIException {

    public StorageUnavailableException(String message) {
        super("AI_STORAGE_UNAVAILABLE", message, HttpStatus.SERVICE_UNAVAILABLE);
    }
}
