package com.civichub.ai.output;

import java.util.List;
import lombok.Builder;
import lombok.Getter;
import lombok.NonNull;
import lombok.Singular;

@Getter
@Builder
public class AIStructuredOutputDefinition {

    @NonNull
    private final String schemaId;

    @NonNull
    private final String version;

    @NonNull
    private final AIOutputType type;

    @Singular
    private final List<AIOutputField> fields;
}
