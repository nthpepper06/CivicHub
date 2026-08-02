package com.civichub.ai.dto;

import jakarta.validation.constraints.NotBlank;
import java.util.HashMap;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder(toBuilder = true)
@NoArgsConstructor
@AllArgsConstructor
public class AIRequest {

    @NotBlank
    private String input;

    private String systemContent;
    private String userContent;
    private String correlationId;
    private String taskType;
    private String templateId;
    private String templateVersion;
    private String outputSchemaId;
    private String outputSchemaVersion;
    private String locale;
    private String model;
    private Double temperature;
    private Integer maxTokens;

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
}
