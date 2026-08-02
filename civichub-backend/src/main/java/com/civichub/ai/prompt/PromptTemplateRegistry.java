package com.civichub.ai.prompt;

import com.civichub.ai.task.AITaskType;

public interface PromptTemplateRegistry {

    PromptTemplate activeTemplate(AITaskType taskType);

    PromptTemplate template(AITaskType taskType, String version);
}
