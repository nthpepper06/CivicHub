package com.civichub.ai.provider;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.exception.UnsupportedAIProviderException;
import com.civichub.ai.model.AIProviderType;
import java.util.List;
import org.junit.jupiter.api.Test;

class AIProviderRegistryTest {

    @Test
    void selectsActiveProviderFromConfiguration() {
        AIProperties properties = new AIProperties();
        properties.setProvider("LOCAL");
        LocalProvider provider = new LocalProvider();
        AIProviderRegistry registry = new AIProviderRegistry(properties, List.of(provider));

        assertThat(registry.activeProvider()).isSameAs(provider);
    }

    @Test
    void rejectsUnknownProviderSafely() {
        AIProperties properties = new AIProperties();
        properties.setProvider("NOT_A_PROVIDER");
        AIProviderRegistry registry = new AIProviderRegistry(properties, List.of(new LocalProvider()));

        assertThatThrownBy(registry::activeProvider)
                .isInstanceOf(UnsupportedAIProviderException.class)
                .hasMessageContaining("NOT_A_PROVIDER");
    }

    @Test
    void failsSafelyWhenConfiguredProviderHasNoImplementation() {
        AIProperties properties = new AIProperties();
        properties.setProvider("OPENAI");
        AIProviderRegistry registry = new AIProviderRegistry(properties, List.of(new LocalProvider()));

        assertThatThrownBy(registry::activeProvider)
                .isInstanceOf(AIProviderUnavailableException.class)
                .hasMessageContaining("OPENAI");
    }

    private static class LocalProvider implements AIProvider {

        @Override
        public AIProviderType type() {
            return AIProviderType.LOCAL;
        }

        @Override
        public AIResponse complete(AIRequest request) {
            return AIResponse.builder().provider(type().name()).build();
        }
    }
}
