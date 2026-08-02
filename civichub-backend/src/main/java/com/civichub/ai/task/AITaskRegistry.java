package com.civichub.ai.task;

public interface AITaskRegistry {

    AITaskDefinition resolve(AITaskType taskType);
}
