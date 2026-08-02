package com.civichub.ai.product.service;

import com.civichub.ai.dto.request.ImageContextAIRequest;
import com.civichub.ai.dto.request.ReportSummaryAIRequest;
import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;
import com.civichub.ai.product.dto.request.DescriptionSuggestionRequest;
import com.civichub.ai.product.dto.request.ImageContextSuggestionRequest;
import com.civichub.ai.product.dto.request.ResolutionSummarySuggestionRequest;
import com.civichub.ai.product.dto.response.ImageContextSuggestionResponse;
import com.civichub.ai.product.dto.response.TextSuggestionResponse;
import com.civichub.ai.service.InternalAIUseCaseService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class ProductAIServiceImpl implements ProductAIService {

    private final InternalAIUseCaseService internalAIUseCaseService;

    @Override
    public TextSuggestionResponse improveReportDescription(DescriptionSuggestionRequest request) {
        ReportSummaryAIRequest internalRequest = new ReportSummaryAIRequest();
        internalRequest.setTitle(request.getTitle());
        internalRequest.setDescription(request.getDescription());
        internalRequest.setLocale(request.getLocale());
        internalRequest.setReportId(request.getReportId());
        ReportSummaryAIResponse response = internalAIUseCaseService.summarizeReport(internalRequest);
        return textSuggestion(response);
    }

    @Override
    public ImageContextSuggestionResponse describeImageContext(ImageContextSuggestionRequest request) {
        ImageContextAIRequest internalRequest = new ImageContextAIRequest();
        internalRequest.setTitle(request.getTitle());
        internalRequest.setLocation(request.getLocation());
        internalRequest.setImageUrl(request.getImageUrl());
        internalRequest.setLocale(request.getLocale());
        internalRequest.setReportId(request.getReportId());
        ImageContextAIResponse response = internalAIUseCaseService.describeImageContext(internalRequest);
        return ImageContextSuggestionResponse.builder()
                .requestId(response.getRequestId())
                .suggestion(response.getContext())
                .confidence(null)
                .provider(response.getProvider())
                .model(response.getModel())
                .build();
    }

    @Override
    public TextSuggestionResponse improveResolutionSummary(ResolutionSummarySuggestionRequest request) {
        ReportSummaryAIRequest internalRequest = new ReportSummaryAIRequest();
        internalRequest.setTitle(request.getTitle());
        internalRequest.setDescription(request.getSummary());
        internalRequest.setLocale(request.getLocale());
        internalRequest.setReportId(request.getReportId());
        ReportSummaryAIResponse response = internalAIUseCaseService.summarizeReport(internalRequest);
        return textSuggestion(response);
    }

    private TextSuggestionResponse textSuggestion(ReportSummaryAIResponse response) {
        return TextSuggestionResponse.builder()
                .requestId(response.getRequestId())
                .suggestion(response.getSummary())
                .provider(response.getProvider())
                .model(response.getModel())
                .build();
    }
}
