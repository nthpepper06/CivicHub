package com.civichub.ai.ops.service;

import com.civichub.ai.ops.dto.AIRecentExecutionResponse;
import com.civichub.ai.ops.model.AIExecutionRecord;
import java.util.List;

public interface AIAuditService {

    void record(AIExecutionRecord record);

    List<AIRecentExecutionResponse> recent(int limit);
}
