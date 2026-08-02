package com.civichub.ai.pipeline.postprocess;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.pipeline.context.AIProcessingContext;

public interface AIResultPostProcessor<T> {

    T postProcess(AIResponse response, AIProcessingContext context);
}
