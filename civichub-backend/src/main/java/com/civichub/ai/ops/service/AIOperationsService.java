package com.civichub.ai.ops.service;

import com.civichub.ai.ops.dto.AIHealthResponse;
import com.civichub.ai.ops.dto.AIProviderOperationsResponse;
import com.civichub.ai.ops.dto.AIRecentExecutionResponse;
import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import java.util.List;

public interface AIOperationsService {

    AIUsageSummaryResponse usage();

    List<AIRecentExecutionResponse> recent(int limit);

    AIProviderOperationsResponse providers();

    AIHealthResponse health();
}
