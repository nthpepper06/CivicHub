package com.civichub.ai.service;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.ops.model.AIExecutionRecord;
import com.civichub.ai.ops.model.AIExecutionStatus;
import com.civichub.ai.ops.service.AIAuditService;
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
    private final AIAuditService aiAuditService;

    @Override
    public AIResponse complete(AIRequest request) {
        AIProvider provider = providerRegistry.activeProvider();
        StopWatch stopWatch = new StopWatch();
        stopWatch.start();
        try {
            AIResponse response = provider.complete(request);
            stopWatch.stop();
            aiLogger.success(provider.type().name(), stopWatch.getTotalTimeMillis(), request, response);
            aiAuditService.record(AIExecutionRecord.builder()
                    .request(request)
                    .response(response)
                    .status(AIExecutionStatus.SUCCESS)
                    .provider(provider.type().name())
                    .model(response == null ? request.getModel() : response.getModel())
                    .latencyMs(stopWatch.getTotalTimeMillis())
                    .build());
            return response;
        } catch (AIException exception) {
            stopWatch.stop();
            aiLogger.failure(provider.type().name(), stopWatch.getTotalTimeMillis(), request, exception.getCode());
            aiAuditService.record(AIExecutionRecord.builder()
                    .request(request)
                    .status(AIExecutionStatus.FAILURE)
                    .provider(provider.type().name())
                    .model(request.getModel())
                    .errorCode(exception.getCode())
                    .latencyMs(stopWatch.getTotalTimeMillis())
                    .build());
            throw exception;
        } catch (RuntimeException exception) {
            stopWatch.stop();
            aiLogger.failure(provider.type().name(), stopWatch.getTotalTimeMillis(), request, "AI_PROVIDER_FAILURE");
            aiAuditService.record(AIExecutionRecord.builder()
                    .request(request)
                    .status(AIExecutionStatus.FAILURE)
                    .provider(provider.type().name())
                    .model(request.getModel())
                    .errorCode("AI_PROVIDER_FAILURE")
                    .latencyMs(stopWatch.getTotalTimeMillis())
                    .build());
            throw exception;
        }
    }
}
