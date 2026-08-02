package com.civichub.ai.dto;

import java.util.HashMap;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIResponse {

    private String output;
    private String provider;
    private String model;
    private AIUsage usage;

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
}
