package com.civichub.ai.execution;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.exception.AITaskDisabledException;
import com.civichub.ai.exception.PromptVariableMissingException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.pipeline.context.AIProcessingRequest;
import com.civichub.ai.pipeline.context.AIProcessingResult;
import com.civichub.ai.pipeline.processor.AIProcessingPipeline;
import com.civichub.ai.service.AIService;
import com.civichub.ai.task.AIRequestFactory;
import com.civichub.ai.task.AITaskDefinition;
import com.civichub.ai.task.AITaskInputType;
import com.civichub.ai.task.AITaskRegistry;
import com.civichub.ai.task.AITaskRequest;
import com.civichub.ai.task.AITaskType;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

class DefaultAITaskExecutionServiceTest {

    private final AIRequestFactory factory = Mockito.mock(AIRequestFactory.class);
    private final AITaskRegistry taskRegistry = Mockito.mock(AITaskRegistry.class);
    private final AIService aiService = Mockito.mock(AIService.class);
    private final AIProcessingPipeline pipeline = Mockito.mock(AIProcessingPipeline.class);
    private final AILogger logger = Mockito.mock(AILogger.class);
    private final DefaultAITaskExecutionService service = new DefaultAITaskExecutionService(
            factory,
            taskRegistry,
            aiService,
            pipeline,
            logger);

    @Test
    void textTaskRoutesThroughAIService() {
        AITaskRequest taskRequest = AITaskRequest.builder().taskType(AITaskType.REPORT_SUMMARY).build();
        AIRequest aiRequest = request("req-1", "REPORT_SUMMARY");
        AIResponse response = AIResponse.builder().provider("LOCAL").model("local").build();

        when(taskRegistry.resolve(AITaskType.REPORT_SUMMARY)).thenReturn(definition(AITaskInputType.TEXT));
        when(factory.create(taskRequest)).thenReturn(aiRequest);
        when(aiService.complete(aiRequest)).thenReturn(response);

        AIResponse result = service.executeText(taskRequest);

        assertThat(result).isSameAs(response);
        assertThat(result.getMetadata()).containsEntry("templateId", "REPORT_SUMMARY_V1");
        verify(aiService).complete(aiRequest);
        verifyNoInteractions(pipeline);
        verify(logger).taskSuccess(
                eq("req-1"),
                eq("REPORT_SUMMARY"),
                eq("REPORT_SUMMARY_V1"),
                eq("v1"),
                eq("report_summary:v1"),
                eq("LOCAL"),
                eq("local"),
                anyLong());
    }

    @Test
    void imageTaskRoutesThroughProcessingPipeline() {
        AITaskRequest taskRequest = AITaskRequest.builder()
                .taskType(AITaskType.IMAGE_CONTEXT)
                .imageReference("/uploads/report-images/street.png")
                .reportId(10L)
                .build();
        AIRequest aiRequest = request("req-2", "IMAGE_CONTEXT");
        AIResponse response = AIResponse.builder().provider("LOCAL").model("local").build();
        AIProcessingResult<AIResponse> pipelineResult = AIProcessingResult.<AIResponse>builder()
                .success(true)
                .provider("LOCAL")
                .payload(response)
                .build();

        when(taskRegistry.resolve(AITaskType.IMAGE_CONTEXT)).thenReturn(definition(AITaskInputType.IMAGE));
        when(factory.create(taskRequest)).thenReturn(aiRequest);
        when(pipeline.process(any())).thenReturn(pipelineResult);

        AIProcessingResult<AIResponse> result = service.executeImage(taskRequest);

        assertThat(result).isSameAs(pipelineResult);
        assertThat(result.getMetadata()).containsEntry("templateId", "IMAGE_CONTEXT_V1");
        assertThat(response.getMetadata()).containsEntry("taskType", "IMAGE_CONTEXT");
        verifyNoInteractions(aiService);
        ArgumentCaptor<AIProcessingRequest> captor = ArgumentCaptor.forClass(AIProcessingRequest.class);
        verify(pipeline).process(captor.capture());
        assertThat(captor.getValue().getRequestId()).isEqualTo("req-2");
        assertThat(captor.getValue().getImageReference()).isEqualTo("/uploads/report-images/street.png");
        assertThat(captor.getValue().getProviderRequest()).isSameAs(aiRequest);
    }

    @Test
    void disabledTaskNeverReachesProvider() {
        AITaskRequest taskRequest = AITaskRequest.builder().taskType(AITaskType.IMAGE_OCR).build();
        when(taskRegistry.resolve(AITaskType.IMAGE_OCR)).thenThrow(new AITaskDisabledException("IMAGE_OCR"));

        assertThatThrownBy(() -> service.executeImage(taskRequest)).isInstanceOf(AITaskDisabledException.class);

        verifyNoInteractions(factory, aiService, pipeline);
    }

    @Test
    void renderingFailureNeverReachesProvider() {
        AITaskRequest taskRequest = AITaskRequest.builder().taskType(AITaskType.REPORT_SUMMARY).build();
        when(taskRegistry.resolve(AITaskType.REPORT_SUMMARY)).thenReturn(definition(AITaskInputType.TEXT));
        when(factory.create(taskRequest)).thenThrow(new PromptVariableMissingException("description"));

        assertThatThrownBy(() -> service.executeText(taskRequest)).isInstanceOf(PromptVariableMissingException.class);

        verifyNoInteractions(aiService, pipeline);
    }

    @Test
    void providerExceptionPropagatesSafely() {
        AITaskRequest taskRequest = AITaskRequest.builder().taskType(AITaskType.REPORT_SUMMARY).build();
        AIRequest aiRequest = request("req-3", "REPORT_SUMMARY");
        when(taskRegistry.resolve(AITaskType.REPORT_SUMMARY)).thenReturn(definition(AITaskInputType.TEXT));
        when(factory.create(taskRequest)).thenReturn(aiRequest);
        when(aiService.complete(aiRequest)).thenThrow(new AIProviderUnavailableException("LOCAL"));

        assertThatThrownBy(() -> service.executeText(taskRequest)).isInstanceOf(AIProviderUnavailableException.class);

        verify(logger).taskFailure(
                eq("req-3"),
                eq("REPORT_SUMMARY"),
                eq("REPORT_SUMMARY_V1"),
                eq("v1"),
                eq("report_summary:v1"),
                eq(null),
                eq("local"),
                anyLong(),
                eq("AI_PROVIDER_UNAVAILABLE"));
    }

    private AITaskDefinition definition(AITaskInputType inputType) {
        return AITaskDefinition.builder()
                .type(inputType == AITaskInputType.TEXT ? AITaskType.REPORT_SUMMARY : AITaskType.IMAGE_CONTEXT)
                .inputType(inputType)
                .build();
    }

    private AIRequest request(String requestId, String taskType) {
        return AIRequest.builder()
                .input("input")
                .systemContent("system")
                .userContent("user")
                .correlationId(requestId)
                .taskType(taskType)
                .templateId(taskType + "_V1")
                .templateVersion("v1")
                .outputSchemaId(taskType.equals("REPORT_SUMMARY") ? "report_summary" : "image_context")
                .outputSchemaVersion("v1")
                .locale("vi-VN")
                .model("local")
                .metadata(java.util.Map.of("templateId", taskType + "_V1"))
                .build();
    }
}
