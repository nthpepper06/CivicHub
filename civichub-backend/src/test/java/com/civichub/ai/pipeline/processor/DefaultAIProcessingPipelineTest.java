package com.civichub.ai.pipeline.processor;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.InvalidImageException;
import com.civichub.ai.exception.PipelineExecutionException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.pipeline.context.AIProcessingContext;
import com.civichub.ai.pipeline.context.AIProcessingRequest;
import com.civichub.ai.pipeline.postprocess.PassThroughAIResultPostProcessor;
import com.civichub.ai.pipeline.preprocess.PassThroughAIImagePreprocessor;
import com.civichub.ai.pipeline.storage.AIImageStorage;
import com.civichub.ai.pipeline.storage.StoredAIImage;
import com.civichub.ai.pipeline.validator.AIImageValidator;
import com.civichub.ai.service.AIService;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

class DefaultAIProcessingPipelineTest {

    private final AIImageStorage storage = Mockito.mock(AIImageStorage.class);
    private final AIImageValidator validator = Mockito.mock(AIImageValidator.class);
    private final AIService aiService = Mockito.mock(AIService.class);
    private final AILogger logger = Mockito.mock(AILogger.class);
    private final DefaultAIProcessingPipeline pipeline = new DefaultAIProcessingPipeline(
            storage,
            validator,
            new PassThroughAIImagePreprocessor(),
            aiService,
            new PassThroughAIResultPostProcessor(),
            logger);

    @Test
    void runsPipelineStagesAndReturnsStructuredResult() {
        StoredAIImage image = StoredAIImage.builder()
                .reference("/uploads/report-images/street.png")
                .path(Path.of("uploads/report-images/street.png").toAbsolutePath())
                .mimeType("image/png")
                .sizeBytes(12)
                .build();
        AIResponse response = AIResponse.builder()
                .provider("LOCAL")
                .model("local")
                .output("structured-result")
                .build();

        when(storage.resolve("/uploads/report-images/street.png")).thenReturn(image);
        when(aiService.complete(any())).thenReturn(response);

        var result = pipeline.process(AIProcessingRequest.builder()
                .requestId("pipe-1")
                .imageReference("/uploads/report-images/street.png")
                .reportId(10L)
                .citizenId(20L)
                .providerRequest(AIRequest.builder().input("process image").build())
                .build());

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getPayload()).isSameAs(response);
        assertThat(result.getProvider()).isEqualTo("LOCAL");
        assertThat(result.getMetadata()).containsEntry("imageSizeBytes", 12L);
        assertThat(result.getMetadata()).containsEntry("preprocessed", false);
        verify(validator).validate(image);
        verify(logger).pipelineStage(eq("pipe-1"), any(), eq("storage"), anyLong(), anyBoolean());
        verify(logger).pipelineStage(eq("pipe-1"), any(), eq("provider"), anyLong(), anyBoolean());
    }

    @Test
    void injectsRequestIdAsProviderCorrelationId() {
        StoredAIImage image = StoredAIImage.builder()
                .reference("/uploads/report-images/street.png")
                .path(Path.of("uploads/report-images/street.png").toAbsolutePath())
                .mimeType("image/png")
                .sizeBytes(12)
                .build();
        when(storage.resolve("/uploads/report-images/street.png")).thenReturn(image);
        when(aiService.complete(any())).thenReturn(AIResponse.builder().provider("LOCAL").build());

        pipeline.process(AIProcessingRequest.builder()
                .requestId("pipe-2")
                .imageReference("/uploads/report-images/street.png")
                .providerRequest(AIRequest.builder().input("process image").correlationId("old").build())
                .build());

        ArgumentCaptor<AIRequest> captor = ArgumentCaptor.forClass(AIRequest.class);
        verify(aiService).complete(captor.capture());
        assertThat(captor.getValue().getCorrelationId()).isEqualTo("pipe-2");
        assertThat(captor.getValue().getInput()).isEqualTo("process image");
    }

    @Test
    void surfacesValidationErrorsWithoutCallingProvider() {
        StoredAIImage image = StoredAIImage.builder()
                .reference("/uploads/report-images/street.png")
                .path(Path.of("uploads/report-images/street.png").toAbsolutePath())
                .mimeType("image/png")
                .sizeBytes(0)
                .build();
        when(storage.resolve("/uploads/report-images/street.png")).thenReturn(image);
        Mockito.doThrow(new InvalidImageException("EMPTY")).when(validator).validate(image);

        assertThatThrownBy(() -> pipeline.process(AIProcessingRequest.builder()
                        .requestId("pipe-3")
                        .imageReference("/uploads/report-images/street.png")
                        .providerRequest(AIRequest.builder().input("process image").build())
                        .build()))
                .isInstanceOf(InvalidImageException.class);

        Mockito.verifyNoInteractions(aiService);
        verify(logger).pipelineFailure(eq("pipe-3"), any(), eq("pipeline"), anyLong(), eq("AI_INVALID_IMAGE"));
    }

    @Test
    void rejectsMissingProviderRequestBeforeStorageLookup() {
        assertThatThrownBy(() -> pipeline.process(AIProcessingRequest.builder()
                        .requestId("pipe-4")
                        .imageReference("/uploads/report-images/street.png")
                        .build()))
                .isInstanceOf(PipelineExecutionException.class)
                .hasMessage("AI provider request is required");

        Mockito.verifyNoInteractions(storage, validator, aiService);
    }
}
