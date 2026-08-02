package com.civichub.ai.provider;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.model.AIProviderType;

public interface AIProvider {

    AIProviderType type();

    AIResponse complete(AIRequest request);
}
