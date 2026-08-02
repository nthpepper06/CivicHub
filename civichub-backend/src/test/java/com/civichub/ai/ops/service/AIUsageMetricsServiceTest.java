package com.civichub.ai.ops.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIUsage;
import com.civichub.ai.ops.model.AIExecutionRecord;
import com.civichub.ai.ops.model.AIExecutionStatus;
import org.junit.jupiter.api.Test;

class AIUsageMetricsServiceTest {

    @Test
    void aggregatesSuccessFailureLatencyTokensAndCost() {
        AIProperties properties = new AIProperties();
        properties.setInputTokenCostPerThousand(0.01);
        properties.setOutputTokenCostPerThousand(0.02);
        InMemoryAIUsageMetricsService service = new InMemoryAIUsageMetricsService(
                properties,
                new AITokenEstimator());

        service.record(AIExecutionRecord.builder()
                .status(AIExecutionStatus.SUCCESS)
                .latencyMs(100)
                .response(AIResponse.builder()
                        .usage(AIUsage.builder()
                                .inputTokens(1000)
                                .outputTokens(500)
                                .totalTokens(1500)
                                .build())
                        .build())
                .build());
        service.record(AIExecutionRecord.builder()
                .status(AIExecutionStatus.FAILURE)
                .latencyMs(300)
                .request(AIRequest.builder().systemContent("System prompt").userContent("User text").build())
                .build());

        var summary = service.summary();

        assertThat(summary.getRequestCount()).isEqualTo(2);
        assertThat(summary.getSuccessCount()).isEqualTo(1);
        assertThat(summary.getFailureCount()).isEqualTo(1);
        assertThat(summary.getAverageLatencyMs()).isEqualTo(200);
        assertThat(summary.getEstimatedTotalTokens()).isGreaterThan(1500);
        assertThat(summary.getEstimatedCost()).isEqualTo(0.02);
    }
}
