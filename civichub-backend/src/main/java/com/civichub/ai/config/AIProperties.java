package com.civichub.ai.config;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app.ai")
public class AIProperties {

    private String provider = "LOCAL";
    private String apiKey;
    private String baseUrl = "https://api.openai.com/v1";
    private String model = "local";
    private Double temperature = 0.2;
    private Duration timeout = Duration.ofSeconds(30);
    private Integer maxTokens = 1024;
    private Boolean enabled = true;
    private Integer retryMaxAttempts = 2;
    private Duration retryBackoff = Duration.ofMillis(200);
    private Integer rateLimitRequests = 20;
    private Duration rateLimitWindow = Duration.ofMinutes(1);
    private Double inputTokenCostPerThousand = 0.0;
    private Double outputTokenCostPerThousand = 0.0;
    private Map<String, TaskProperties> tasks = new HashMap<>();

    @Getter
    @Setter
    public static class TaskProperties {
        private Boolean enabled;
        private String model;
        private Double temperature;
        private Integer maxTokens;
        private String templateVersion;
    }
}
