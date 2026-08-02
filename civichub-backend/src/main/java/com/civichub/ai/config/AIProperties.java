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
    private String model = "local";
    private Double temperature = 0.2;
    private Duration timeout = Duration.ofSeconds(30);
    private Integer maxTokens = 1024;
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
