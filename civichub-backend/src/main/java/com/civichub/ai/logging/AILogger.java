package com.civichub.ai.logging;

import com.civichub.ai.dto.AIResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class AILogger {

    public void success(String provider, long latencyMs, AIResponse response) {
        Integer totalTokens = response == null || response.getUsage() == null
                ? null
                : response.getUsage().getTotalTokens();
        log.info(
                "ai_request provider={} latencyMs={} success=true totalTokens={}",
                provider,
                latencyMs,
                totalTokens);
    }

    public void failure(String provider, long latencyMs, String code) {
        log.warn(
                "ai_request provider={} latencyMs={} success=false errorCode={}",
                provider,
                latencyMs,
                code);
    }
}
