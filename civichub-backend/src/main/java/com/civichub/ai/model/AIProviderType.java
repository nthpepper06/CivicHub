package com.civichub.ai.model;

import java.util.Arrays;
import java.util.Optional;

public enum AIProviderType {
    OPENAI,
    GEMINI,
    AZURE_OPENAI,
    OLLAMA,
    LOCAL;

    public static Optional<AIProviderType> from(String value) {
        if (value == null || value.isBlank()) {
            return Optional.empty();
        }
        return Arrays.stream(values())
                .filter(type -> type.name().equalsIgnoreCase(value.trim()))
                .findFirst();
    }
}
