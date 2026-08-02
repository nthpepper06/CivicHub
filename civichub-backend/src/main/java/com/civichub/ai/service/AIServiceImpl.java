package com.civichub.ai.service;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.provider.AIProvider;
import com.civichub.ai.provider.AIProviderRegistry;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StopWatch;

@Service
@RequiredArgsConstructor
public class AIServiceImpl implements AIService {

    private final AIProviderRegistry providerRegistry;
    private final AILogger aiLogger;

    @Override
    public AIResponse complete(AIRequest request) {
        AIProvider provider = providerRegistry.activeProvider();
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        try {
            AIResponse response = provider.complete(request);
            stopWatch.stop();
            aiLogger.success(provider.type().name(), stopWatch.getTotalTimeMillis(), response);
            return response;
        } catch (AIException exception) {
            stopWatch.stop();
            aiLogger.failure(provider.type().name(), stopWatch.getTotalTimeMillis(), exception.getCode());
            throw exception;
        } catch (RuntimeException exception) {
            stopWatch.stop();
            aiLogger.failure(provider.type().name(), stopWatch.getTotalTimeMillis(), "AI_PROVIDER_FAILURE");
            throw exception;
        }
    }
}
