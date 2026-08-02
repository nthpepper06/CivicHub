package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public abstract class AIException extends RuntimeException {

    private final String code;
    private final HttpStatus status;

    protected AIException(String code, String message, HttpStatus status) {
        super(message);
        this.code = code;
        this.status = status;
    }

    public String getCode() {
        return code;
    }

    public HttpStatus getStatus() {
        return status;
    }
}
