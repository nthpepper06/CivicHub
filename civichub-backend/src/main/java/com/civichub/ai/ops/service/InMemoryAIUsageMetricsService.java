package com.civichub.ai.ops.service;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIUsage;
import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import com.civichub.ai.ops.model.AIExecutionRecord;
import com.civichub.ai.ops.model.AIExecutionStatus;
import java.util.concurrent.atomic.DoubleAdder;
import java.util.concurrent.atomic.LongAdder;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class InMemoryAIUsageMetricsService implements AIUsageMetricsService {

    private final AIProperties properties;
    private final AITokenEstimator tokenEstimator;
    private final LongAdder requestCount = new LongAdder();
    private final LongAdder successCount = new LongAdder();
    private final LongAdder failureCount = new LongAdder();
    private final LongAdder latencyTotal = new LongAdder();
    private final LongAdder promptTokens = new LongAdder();
    private final LongAdder completionTokens = new LongAdder();
    private final LongAdder totalTokens = new LongAdder();
    private final DoubleAdder estimatedCost = new DoubleAdder();

    @Override
    public void record(AIExecutionRecord record) {
        requestCount.increment();
        latencyTotal.add(record.getLatencyMs());
        if (record.getStatus() == AIExecutionStatus.SUCCESS) {
            successCount.increment();
        } else {
            failureCount.increment();
        }
        AIUsage usage = record.getResponse() == null ? null : record.getResponse().getUsage();
        if (usage != null) {
            addIfPresent(promptTokens, usage.getInputTokens());
            addIfPresent(completionTokens, usage.getOutputTokens());
            addIfPresent(totalTokens, usage.getTotalTokens());
            estimatedCost.add(cost(usage));
        } else {
            int prompt = record.getRequest() == null
                    ? 0
                    : tokenEstimator.estimate(record.getRequest().getSystemContent())
                            + tokenEstimator.estimate(record.getRequest().getUserContent());
            int completion = record.getResponse() == null
                    ? 0
                    : tokenEstimator.estimate(record.getResponse().getOutput());
            promptTokens.add(prompt);
            completionTokens.add(completion);
            totalTokens.add(prompt + completion);
        }
    }

    @Override
    public AIUsageSummaryResponse summary() {
        long requests = requestCount.sum();
        return AIUsageSummaryResponse.builder()
                .requestCount(requests)
                .successCount(successCount.sum())
                .failureCount(failureCount.sum())
                .averageLatencyMs(requests == 0 ? 0 : (double) latencyTotal.sum() / requests)
                .estimatedPromptTokens((int) promptTokens.sum())
                .estimatedCompletionTokens((int) completionTokens.sum())
                .estimatedTotalTokens((int) totalTokens.sum())
                .estimatedCost(estimatedCost.sum())
                .build();
    }

    private void addIfPresent(LongAdder adder, Integer value) {
        if (value != null) {
            adder.add(value);
        }
    }

    private double cost(AIUsage usage) {
        double input = usage.getInputTokens() == null ? 0 : usage.getInputTokens();
        double output = usage.getOutputTokens() == null ? 0 : usage.getOutputTokens();
        return input / 1000.0 * properties.getInputTokenCostPerThousand()
                + output / 1000.0 * properties.getOutputTokenCostPerThousand();
    }
}
