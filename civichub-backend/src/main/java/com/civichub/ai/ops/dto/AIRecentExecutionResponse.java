package com.civichub.ai.ops.dto;

import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AIRecentExecutionResponse {

    private final Long id;
    private final String requestId;
    private final String correlationId;
    private final String taskType;
    private final String provider;
    private final String model;
    private final String templateId;
    private final String templateVersion;
    private final String schemaId;
    private final String schemaVersion;
    private final String status;
    private final String errorCode;
    private final Long latencyMs;
    private final Integer totalTokens;
    private final Double estimatedCost;
    private final LocalDateTime createdAt;
}
