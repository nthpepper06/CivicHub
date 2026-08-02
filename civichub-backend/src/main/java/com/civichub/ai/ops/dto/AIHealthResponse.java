package com.civichub.ai.ops.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AIHealthResponse {

    private final boolean aiModuleEnabled;
    private final String configuredProvider;
    private final boolean providerEnabled;
    private final boolean configurationValid;
    private final String model;
}
