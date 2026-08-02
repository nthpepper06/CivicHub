package com.civichub.ai.service;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;

public interface AIService {

    AIResponse complete(AIRequest request);
}
