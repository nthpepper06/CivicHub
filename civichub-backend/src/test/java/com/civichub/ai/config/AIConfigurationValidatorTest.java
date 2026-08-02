package com.civichub.ai.config;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.time.Duration;
import org.junit.jupiter.api.Test;

class AIConfigurationValidatorTest {

    @Test
    void validLocalConfigurationPasses() {
        AIProperties properties = validProperties();

        assertThatCode(() -> new AIConfigurationValidator(properties).validate()).doesNotThrowAnyException();
    }

    @Test
    void disabledAiSkipsProviderValidation() {
        AIProperties properties = validProperties();
        properties.setEnabled(false);
        properties.setProvider("UNKNOWN");

        assertThatCode(() -> new AIConfigurationValidator(properties).validate()).doesNotThrowAnyException();
    }

    @Test
    void unsupportedProviderFailsStartupValidation() {
        AIProperties properties = validProperties();
        properties.setProvider("UNKNOWN");

        assertThatThrownBy(() -> new AIConfigurationValidator(properties).validate())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("Unsupported AI provider");
    }

    @Test
    void openAiRequiresApiKeyWhenEnabled() {
        AIProperties properties = validProperties();
        properties.setProvider("OPENAI");
        properties.setApiKey("");

        assertThatThrownBy(() -> new AIConfigurationValidator(properties).validate())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("OpenAI API key is required");
    }

    @Test
    void invalidRateLimitFailsStartupValidation() {
        AIProperties properties = validProperties();
        properties.setRateLimitRequests(0);

        assertThatThrownBy(() -> new AIConfigurationValidator(properties).validate())
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("AI rate limit requests must be positive");
    }

    private AIProperties validProperties() {
        AIProperties properties = new AIProperties();
        properties.setProvider("LOCAL");
        properties.setModel("local-test");
        properties.setTemperature(0.2);
        properties.setMaxTokens(128);
        properties.setTimeout(Duration.ofSeconds(5));
        properties.setRetryMaxAttempts(2);
        properties.setRetryBackoff(Duration.ofMillis(1));
        properties.setRateLimitRequests(5);
        properties.setRateLimitWindow(Duration.ofMinutes(1));
        properties.setInputTokenCostPerThousand(0.0);
        properties.setOutputTokenCostPerThousand(0.0);
        return properties;
    }
}
