package com.civichub.ai.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ImageContextAIResponse {

    private final String requestId;
    private final String context;
    private final String provider;
    private final String model;
    private final String taskType;
    private final String templateId;
    private final String templateVersion;
    private final String outputSchemaId;
    private final String outputSchemaVersion;
}
