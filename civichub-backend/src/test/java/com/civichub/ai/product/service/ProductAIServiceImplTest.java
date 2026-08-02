package com.civichub.ai.product.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentCaptor.forClass;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.ai.dto.request.ImageContextAIRequest;
import com.civichub.ai.dto.request.ReportSummaryAIRequest;
import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;
import com.civichub.ai.product.dto.request.DescriptionSuggestionRequest;
import com.civichub.ai.product.dto.request.ImageContextSuggestionRequest;
import com.civichub.ai.product.dto.request.ResolutionSummarySuggestionRequest;
import com.civichub.ai.service.InternalAIUseCaseService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;

class ProductAIServiceImplTest {

    private final InternalAIUseCaseService internalAIUseCaseService = Mockito.mock(InternalAIUseCaseService.class);
    private final ProductAIServiceImpl service = new ProductAIServiceImpl(internalAIUseCaseService);

    @Test
    void improveReportDescriptionDelegatesToInternalUseCase() {
        when(internalAIUseCaseService.summarizeReport(Mockito.any())).thenReturn(summaryResponse("Clear description."));

        DescriptionSuggestionRequest request = new DescriptionSuggestionRequest();
        request.setTitle("Broken sidewalk");
        request.setDescription("bad paving");
        request.setLocale("en");
        request.setReportId(12L);

        var response = service.improveReportDescription(request);

        assertThat(response.getSuggestion()).isEqualTo("Clear description.");
        ArgumentCaptor<ReportSummaryAIRequest> captor = forClass(ReportSummaryAIRequest.class);
        verify(internalAIUseCaseService).summarizeReport(captor.capture());
        assertThat(captor.getValue().getTitle()).isEqualTo("Broken sidewalk");
        assertThat(captor.getValue().getDescription()).isEqualTo("bad paving");
        assertThat(captor.getValue().getReportId()).isEqualTo(12L);
    }

    @Test
    void improveResolutionSummaryDelegatesToReportSummaryTask() {
        when(internalAIUseCaseService.summarizeReport(Mockito.any())).thenReturn(summaryResponse("Resolved safely."));

        ResolutionSummarySuggestionRequest request = new ResolutionSummarySuggestionRequest();
        request.setTitle("Broken sidewalk");
        request.setSummary("fixed path");

        var response = service.improveResolutionSummary(request);

        assertThat(response.getSuggestion()).isEqualTo("Resolved safely.");
        ArgumentCaptor<ReportSummaryAIRequest> captor = forClass(ReportSummaryAIRequest.class);
        verify(internalAIUseCaseService).summarizeReport(captor.capture());
        assertThat(captor.getValue().getDescription()).isEqualTo("fixed path");
    }

    @Test
    void imageContextDelegatesToInternalImageUseCase() {
        when(internalAIUseCaseService.describeImageContext(Mockito.any())).thenReturn(ImageContextAIResponse.builder()
                .requestId("req-2")
                .context("Image shows road damage.")
                .provider("OPENAI")
                .model("gpt-test")
                .build());

        ImageContextSuggestionRequest request = new ImageContextSuggestionRequest();
        request.setTitle("Road damage");
        request.setLocation("12 Nguyen Hue");
        request.setImageUrl("/uploads/reports/road.png");

        var response = service.describeImageContext(request);

        assertThat(response.getSuggestion()).isEqualTo("Image shows road damage.");
        assertThat(response.getConfidence()).isNull();
        ArgumentCaptor<ImageContextAIRequest> captor = forClass(ImageContextAIRequest.class);
        verify(internalAIUseCaseService).describeImageContext(captor.capture());
        assertThat(captor.getValue().getImageUrl()).isEqualTo("/uploads/reports/road.png");
        assertThat(captor.getValue().getLocation()).isEqualTo("12 Nguyen Hue");
    }

    private ReportSummaryAIResponse summaryResponse(String summary) {
        return ReportSummaryAIResponse.builder()
                .requestId("req-1")
                .summary(summary)
                .provider("OPENAI")
                .model("gpt-test")
                .build();
    }
}
