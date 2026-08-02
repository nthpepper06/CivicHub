package com.civichub.ai.pipeline.processor;

import com.civichub.ai.dto.AIError;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIException;
import com.civichub.ai.exception.PipelineExecutionException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.pipeline.context.AIProcessingContext;
import com.civichub.ai.pipeline.context.AIProcessingRequest;
import com.civichub.ai.pipeline.context.AIProcessingResult;
import com.civichub.ai.pipeline.postprocess.AIResultPostProcessor;
import com.civichub.ai.pipeline.preprocess.AIImagePreprocessor;
import com.civichub.ai.pipeline.preprocess.PreprocessedAIImage;
import com.civichub.ai.pipeline.storage.AIImageStorage;
import com.civichub.ai.pipeline.storage.StoredAIImage;
import com.civichub.ai.pipeline.validator.AIImageValidator;
import com.civichub.ai.service.AIService;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.util.StopWatch;

@Service
@RequiredArgsConstructor
public class DefaultAIProcessingPipeline implements AIProcessingPipeline {

    private final AIImageStorage imageStorage;
    private final AIImageValidator imageValidator;
    private final AIImagePreprocessor imagePreprocessor;
    private final AIService aiService;
    private final AIResultPostProcessor<AIResponse> postProcessor;
    private final AILogger aiLogger;

    @Override
    public AIProcessingResult<AIResponse> process(AIProcessingRequest request) {
        if (request == null) {
            throw new PipelineExecutionException("AI processing request is required");
        }
        if (request.getProviderRequest() == null) {
            throw new PipelineExecutionException("AI provider request is required");
        }
        StopWatch totalWatch = new StopWatch();
        totalWatch.start();
        AIProcessingContext context = buildContext(request);
        try {
            StoredAIImage storedImage = resolve(request, context);
            validate(storedImage, context);
            PreprocessedAIImage preprocessedImage = preprocess(storedImage, context);
            AIResponse providerResponse = executeProvider(request.getProviderRequest(), preprocessedImage, context);
            AIResponse payload = postProcess(providerResponse, context);
            totalWatch.stop();
            return AIProcessingResult.<AIResponse>builder()
                    .success(true)
                    .processingTimeMs(totalWatch.getTotalTimeMillis())
                    .provider(providerResponse.getProvider())
                    .payload(payload)
                    .metadata(context.getMetadata())
                    .build();
        } catch (AIException exception) {
            stopIfRunning(totalWatch);
            aiLogger.pipelineFailure(
                    context.getRequestId(),
                    context.getProvider(),
                    "pipeline",
                    totalWatch.getTotalTimeMillis(),
                    exception.getCode());
            throw exception;
        } catch (RuntimeException exception) {
            stopIfRunning(totalWatch);
            aiLogger.pipelineFailure(
                    context.getRequestId(),
                    context.getProvider(),
                    "pipeline",
                    totalWatch.getTotalTimeMillis(),
                    "AI_PIPELINE_EXECUTION_FAILED");
            throw new PipelineExecutionException("AI processing pipeline failed");
        }
    }

    private StoredAIImage resolve(AIProcessingRequest request, AIProcessingContext context) {
        StopWatch watch = start();
        StoredAIImage image = imageStorage.resolve(request.getImageReference());
        stopAndLog(watch, context, "storage", true);
        context.setImagePath(image.getPath());
        context.setMimeType(image.getMimeType());
        context.getMetadata().put("imageSizeBytes", image.getSizeBytes());
        return image;
    }

    private void validate(StoredAIImage storedImage, AIProcessingContext context) {
        StopWatch watch = start();
        imageValidator.validate(storedImage);
        stopAndLog(watch, context, "validation", true);
    }

    private PreprocessedAIImage preprocess(StoredAIImage storedImage, AIProcessingContext context) {
        StopWatch watch = start();
        PreprocessedAIImage image = imagePreprocessor.preprocess(storedImage, context);
        stopAndLog(watch, context, "preprocess", true);
        context.getMetadata().putAll(image.getMetadata());
        return image;
    }

    private AIResponse executeProvider(
            AIRequest providerRequest,
            PreprocessedAIImage preprocessedImage,
            AIProcessingContext context) {
        StopWatch watch = start();
        AIRequest request = providerRequest.toBuilder()
                .correlationId(context.getRequestId())
                .build();
        context.getMetadata().put("preprocessedMimeType", preprocessedImage.getMimeType());
        AIResponse response = aiService.complete(request);
        stopAndLog(watch, context, "provider", true);
        context.setProvider(response.getProvider());
        return response;
    }

    private AIResponse postProcess(AIResponse providerResponse, AIProcessingContext context) {
        StopWatch watch = start();
        AIResponse response = postProcessor.postProcess(providerResponse, context);
        stopAndLog(watch, context, "postprocess", true);
        return response;
    }

    private AIProcessingContext buildContext(AIProcessingRequest request) {
        Map<String, Object> metadata = new HashMap<>();
        if (request.getMetadata() != null) {
            metadata.putAll(request.getMetadata());
        }
        return AIProcessingContext.builder()
                .requestId(StringUtils.hasText(request.getRequestId())
                        ? request.getRequestId()
                        : UUID.randomUUID().toString())
                .imageReference(request.getImageReference())
                .reportId(request.getReportId())
                .citizenId(request.getCitizenId())
                .locale(request.getLocale())
                .traceId(request.getTraceId())
                .metadata(metadata)
                .build();
    }

    private StopWatch start() {
        StopWatch watch = new StopWatch();
        watch.start();
        return watch;
    }

    private void stopAndLog(StopWatch watch, AIProcessingContext context, String stage, boolean success) {
        watch.stop();
        aiLogger.pipelineStage(
                context.getRequestId(),
                context.getProvider(),
                stage,
                watch.getTotalTimeMillis(),
                success);
    }

    private void stopIfRunning(StopWatch watch) {
        if (watch.isRunning()) {
            watch.stop();
        }
    }
}
