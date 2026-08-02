package com.civichub.ai.model;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AIProviderTypeTest {

    @Test
    void parsesProviderNamesCaseInsensitively() {
        assertThat(AIProviderType.from("openai")).contains(AIProviderType.OPENAI);
        assertThat(AIProviderType.from("AZURE_OPENAI")).contains(AIProviderType.AZURE_OPENAI);
        assertThat(AIProviderType.from(" local ")).contains(AIProviderType.LOCAL);
    }

    @Test
    void rejectsUnknownProviderNamesSafely() {
        assertThat(AIProviderType.from("unknown")).isEmpty();
        assertThat(AIProviderType.from(null)).isEmpty();
    }
}
