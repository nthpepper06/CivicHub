package com.civichub.ai.ops.dto;

import java.util.List;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AIProviderOperationsResponse {

    private final String configuredProvider;
    private final boolean aiEnabled;
    private final List<String> availableProviders;
    private final String model;
    private final long timeoutMs;
    private final int retryMaxAttempts;
}
