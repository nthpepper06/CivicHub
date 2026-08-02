package com.civichub.ai.ops.service;

import com.civichub.ai.config.AIConfigurationValidator;
import com.civichub.ai.config.AIProperties;
import com.civichub.ai.ops.dto.AIHealthResponse;
import com.civichub.ai.ops.dto.AIProviderOperationsResponse;
import com.civichub.ai.ops.dto.AIRecentExecutionResponse;
import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import com.civichub.ai.provider.AIProviderRegistry;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AIOperationsServiceImpl implements AIOperationsService {

    private final AIProperties properties;
    private final AIProviderRegistry providerRegistry;
    private final AIUsageMetricsService metricsService;
    private final AIAuditService auditService;
    private final AIConfigurationValidator configurationValidator;

    @Override
    public AIUsageSummaryResponse usage() {
        return metricsService.summary();
    }

    @Override
    public List<AIRecentExecutionResponse> recent(int limit) {
        return auditService.recent(limit);
    }

    @Override
    public AIProviderOperationsResponse providers() {
        return AIProviderOperationsResponse.builder()
                .configuredProvider(properties.getProvider())
                .aiEnabled(Boolean.TRUE.equals(properties.getEnabled()))
                .availableProviders(providerRegistry.availableProviderTypes().stream()
                        .map(Enum::name)
                        .sorted()
                        .toList())
                .model(properties.getModel())
                .timeoutMs(properties.getTimeout().toMillis())
                .retryMaxAttempts(properties.getRetryMaxAttempts())
                .build();
    }

    @Override
    public AIHealthResponse health() {
        boolean configurationValid = true;
        try {
            configurationValidator.validate();
        } catch (RuntimeException exception) {
            configurationValid = false;
        }
        return AIHealthResponse.builder()
                .aiModuleEnabled(Boolean.TRUE.equals(properties.getEnabled()))
                .configuredProvider(properties.getProvider())
                .providerEnabled(providerRegistry.availableProviderTypes().stream()
                        .anyMatch(type -> type.name().equalsIgnoreCase(properties.getProvider())))
                .configurationValid(configurationValid)
                .model(properties.getModel())
                .build();
    }
}
