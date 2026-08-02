package com.civichub.ai.execution;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.pipeline.context.AIProcessingResult;
import com.civichub.ai.task.AITaskRequest;

public interface AITaskExecutionService {

    AIResponse executeText(AITaskRequest request);

    AIProcessingResult<AIResponse> executeImage(AITaskRequest request);
}
