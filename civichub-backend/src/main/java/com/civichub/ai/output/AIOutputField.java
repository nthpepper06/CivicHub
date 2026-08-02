package com.civichub.ai.output;

import java.util.Set;
import lombok.Builder;
import lombok.Getter;
import lombok.NonNull;
import lombok.Singular;

@Getter
@Builder
public class AIOutputField {

    @NonNull
    private final String name;

    @NonNull
    private final AIOutputFieldType type;

    @Builder.Default
    private final boolean required = false;

    private final Integer maxLength;

    @Singular
    private final Set<String> enumValues;
}
