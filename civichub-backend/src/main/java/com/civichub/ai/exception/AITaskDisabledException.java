package com.civichub.ai.exception;

import org.springframework.http.HttpStatus;

public class AITaskDisabledException extends AIException {

    public AITaskDisabledException(String taskType) {
        super("AI_TASK_DISABLED", "AI task is disabled", HttpStatus.FORBIDDEN);
    }
}
