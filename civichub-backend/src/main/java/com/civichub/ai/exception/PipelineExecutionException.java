package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class PipelineExecutionException extends AIException {

    public PipelineExecutionException(String message) {
        super("AI_PIPELINE_EXECUTION_FAILED", message, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
