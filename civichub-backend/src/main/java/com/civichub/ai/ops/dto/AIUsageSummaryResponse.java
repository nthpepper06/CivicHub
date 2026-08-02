package com.civichub.ai.ops.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AIUsageSummaryResponse {

    private final long requestCount;
    private final long successCount;
    private final long failureCount;
    private final double averageLatencyMs;
    private final int estimatedPromptTokens;
    private final int estimatedCompletionTokens;
    private final int estimatedTotalTokens;
    private final double estimatedCost;
}
