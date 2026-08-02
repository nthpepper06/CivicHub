package com.civichub.ai.ops.service;

import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import com.civichub.ai.ops.model.AIExecutionRecord;

public interface AIUsageMetricsService {

    void record(AIExecutionRecord record);

    AIUsageSummaryResponse summary();
}
