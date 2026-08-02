package com.civichub.ai.config;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;
import org.springframework.context.annotation.Configuration;

class AIPropertiesTest {

    private final ApplicationContextRunner contextRunner = new ApplicationContextRunner()
            .withUserConfiguration(TestConfig.class);

    @Test
    void bindsAIConfigurationWithoutExposingApiKey() {
        contextRunner
                .withPropertyValues(
                        "app.ai.provider=OPENAI",
                        "app.ai.api-key=secret-key",
                        "app.ai.model=gpt-test",
                        "app.ai.temperature=0.4",
                        "app.ai.timeout=45s",
                        "app.ai.max-tokens=2048")
                .run(context -> {
                    AIProperties properties = context.getBean(AIProperties.class);

                    assertThat(properties.getProvider()).isEqualTo("OPENAI");
                    assertThat(properties.getApiKey()).isEqualTo("secret-key");
                    assertThat(properties.getModel()).isEqualTo("gpt-test");
                    assertThat(properties.getTemperature()).isEqualTo(0.4);
                    assertThat(properties.getTimeout().getSeconds()).isEqualTo(45);
                    assertThat(properties.getMaxTokens()).isEqualTo(2048);
                });
    }

    @Configuration(proxyBeanMethods = false)
    @EnableConfigurationProperties(AIProperties.class)
    static class TestConfig {
    }
}
