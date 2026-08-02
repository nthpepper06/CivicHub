package com.civichub.ai.task;

import java.util.Set;
import lombok.Builder;
import lombok.Getter;
import lombok.NonNull;
import lombok.Singular;

@Getter
@Builder
public class AITaskDefinition {

    @NonNull
    private final AITaskType type;

    @NonNull
    private final AITaskInputType inputType;

    @Builder.Default
    private final boolean enabled = true;

    @Singular
    private final Set<String> requiredVariables;

    @Singular
    private final Set<String> optionalVariables;
}
