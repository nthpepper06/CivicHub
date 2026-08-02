package com.civichub.ai.prompt;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class RenderedPrompt {

    private final String systemContent;
    private final String userContent;

    public String combinedInput() {
        return "System:\n%s\n\nUser:\n%s".formatted(systemContent, userContent);
    }
}
