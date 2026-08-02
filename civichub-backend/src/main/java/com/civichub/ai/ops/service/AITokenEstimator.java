package com.civichub.ai.ops.service;

import org.springframework.stereotype.Component;

@Component
public class AITokenEstimator {

    public int estimate(String value) {
        if (value == null || value.isBlank()) {
            return 0;
        }
        return Math.max(1, (int) Math.ceil(value.length() / 4.0));
    }
}
