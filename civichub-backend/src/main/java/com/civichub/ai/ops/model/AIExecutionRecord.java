package com.civichub.ai.ops.model;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIRequest;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AIExecutionRecord {

    private final AIRequest request;
    private final AIResponse response;
    private final AIExecutionStatus status;
    private final String provider;
    private final String model;
    private final String errorCode;
    private final long latencyMs;
}
