package com.civichub.ai.execution;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIException;
import com.civichub.ai.exception.PipelineExecutionException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.pipeline.context.AIProcessingRequest;
import com.civichub.ai.pipeline.context.AIProcessingResult;
import com.civichub.ai.pipeline.processor.AIProcessingPipeline;
import com.civichub.ai.service.AIService;
import com.civichub.ai.task.AIRequestFactory;
import com.civichub.ai.task.AITaskInputType;
import com.civichub.ai.task.AITaskRegistry;
import com.civichub.ai.task.AITaskRequest;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StopWatch;

@Service
@RequiredArgsConstructor
public class DefaultAITaskExecutionService implements AITaskExecutionService {

    private final AIRequestFactory requestFactory;
    private final AITaskRegistry taskRegistry;
    private final AIService aiService;
    private final AIProcessingPipeline processingPipeline;
    private final AILogger aiLogger;

    @Override
    public AIResponse executeText(AITaskRequest request) {
        if (taskRegistry.resolve(request.getTaskType()).getInputType() != AITaskInputType.TEXT) {
            throw new PipelineExecutionException("AI task requires image processing");
        }
        AIRequest aiRequest = requestFactory.create(request);
        StopWatch watch = start();
        try {
            AIResponse response = aiService.complete(aiRequest);
            attachMetadata(response, aiRequest);
            watch.stop();
            aiLogger.taskSuccess(
                    aiRequest.getCorrelationId(),
                    aiRequest.getTaskType(),
                    aiRequest.getTemplateId(),
                    aiRequest.getTemplateVersion(),
                    outputSchema(aiRequest),
                    response.getProvider(),
                    response.getModel(),
                    watch.getTotalTimeMillis());
            return response;
        } catch (AIException exception) {
            stopIfRunning(watch);
            aiLogger.taskFailure(
                    aiRequest.getCorrelationId(),
                    aiRequest.getTaskType(),
                    aiRequest.getTemplateId(),
                    aiRequest.getTemplateVersion(),
                    outputSchema(aiRequest),
                    null,
                    aiRequest.getModel(),
                    watch.getTotalTimeMillis(),
                    exception.getCode());
            throw exception;
        }
    }

    @Override
    public AIProcessingResult<AIResponse> executeImage(AITaskRequest request) {
        if (taskRegistry.resolve(request.getTaskType()).getInputType() != AITaskInputType.IMAGE) {
            throw new PipelineExecutionException("AI task does not require image processing");
        }
        AIRequest aiRequest = requestFactory.create(request);
        StopWatch watch = start();
        try {
            AIProcessingResult<AIResponse> result = processingPipeline.process(AIProcessingRequest.builder()
                    .requestId(aiRequest.getCorrelationId())
                    .imageReference(request.getImageReference())
                    .reportId(request.getReportId())
                    .citizenId(request.getCitizenId())
                    .locale(aiRequest.getLocale())
                    .traceId(String.valueOf((request.getMetadata() == null ? Map.of() : request.getMetadata())
                            .getOrDefault("traceId", "")))
                    .providerRequest(aiRequest)
                    .metadata(aiRequest.getMetadata())
                    .build());
            if (result.getPayload() != null) {
                attachMetadata(result.getPayload(), aiRequest);
            }
            result.getMetadata().putAll(aiRequest.getMetadata());
            watch.stop();
            AIResponse payload = result.getPayload();
            aiLogger.taskSuccess(
                    aiRequest.getCorrelationId(),
                    aiRequest.getTaskType(),
                    aiRequest.getTemplateId(),
                    aiRequest.getTemplateVersion(),
                    outputSchema(aiRequest),
                    result.getProvider(),
                    payload == null ? aiRequest.getModel() : payload.getModel(),
                    watch.getTotalTimeMillis());
            return result;
        } catch (AIException exception) {
            stopIfRunning(watch);
            aiLogger.taskFailure(
                    aiRequest.getCorrelationId(),
                    aiRequest.getTaskType(),
                    aiRequest.getTemplateId(),
                    aiRequest.getTemplateVersion(),
                    outputSchema(aiRequest),
                    null,
                    aiRequest.getModel(),
                    watch.getTotalTimeMillis(),
                    exception.getCode());
            throw exception;
        }
    }

    private String outputSchema(AIRequest request) {
        return request.getOutputSchemaId() + ":" + request.getOutputSchemaVersion();
    }

    private void attachMetadata(AIResponse response, AIRequest request) {
        if (response == null) {
            return;
        }
        response.getMetadata().putAll(Map.of(
                "taskType", request.getTaskType(),
                "templateId", request.getTemplateId(),
                "templateVersion", request.getTemplateVersion(),
                "outputSchemaId", request.getOutputSchemaId(),
                "outputSchemaVersion", request.getOutputSchemaVersion(),
                "correlationId", request.getCorrelationId()));
    }

    private StopWatch start() {
        StopWatch watch = new StopWatch();
        watch.start();
        return watch;
    }

    private void stopIfRunning(StopWatch watch) {
        if (watch.isRunning()) {
            watch.stop();
        }
    }
}
