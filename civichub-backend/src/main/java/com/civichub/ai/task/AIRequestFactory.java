package com.civichub.ai.task;

import com.civichub.ai.dto.AIRequest;

public interface AIRequestFactory {

    AIRequest create(AITaskRequest request);
}
