package com.civichub.ai.pipeline.processor;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.pipeline.context.AIProcessingRequest;
import com.civichub.ai.pipeline.context.AIProcessingResult;

public interface AIProcessingPipeline {

    AIProcessingResult<AIResponse> process(AIProcessingRequest request);
}
