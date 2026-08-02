package com.civichub.ai.provider;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.model.AIProviderType;
import org.springframework.stereotype.Component;

@Component
public class LocalAIProvider implements AIProvider {

    @Override
    public AIProviderType type() {
        return AIProviderType.LOCAL;
    }

    @Override
    public AIResponse complete(AIRequest request) {
        throw new AIProviderUnavailableException(type().name());
    }
}
