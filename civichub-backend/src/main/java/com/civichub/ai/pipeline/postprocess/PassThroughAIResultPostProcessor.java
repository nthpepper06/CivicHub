package com.civichub.ai.pipeline.postprocess;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.pipeline.context.AIProcessingContext;
import org.springframework.stereotype.Component;

@Component
public class PassThroughAIResultPostProcessor implements AIResultPostProcessor<AIResponse> {

    @Override
    public AIResponse postProcess(AIResponse response, AIProcessingContext context) {
        return response;
    }
}
