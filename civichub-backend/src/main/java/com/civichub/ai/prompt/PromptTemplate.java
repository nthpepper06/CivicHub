package com.civichub.ai.prompt;

import com.civichub.ai.task.AITaskType;
import java.util.Set;
import lombok.Builder;
import lombok.Getter;
import lombok.NonNull;
import lombok.Singular;

@Getter
@Builder
public class PromptTemplate {

    @NonNull
    private final String templateId;

    @NonNull
    private final AITaskType taskType;

    @NonNull
    private final String version;

    @NonNull
    private final String systemInstruction;

    @NonNull
    private final String userTemplate;

    @Singular
    private final Set<String> requiredVariables;

    @Singular
    private final Set<String> optionalVariables;

    @NonNull
    private final String outputSchemaId;

    @NonNull
    private final String outputSchemaVersion;

    @Builder.Default
    private final PromptLocalePolicy localePolicy = PromptLocalePolicy.USE_REQUEST_LOCALE;

    @Builder.Default
    private final boolean enabled = true;
}
