package com.civichub.ai.product.service;

import com.civichub.ai.product.dto.request.DescriptionSuggestionRequest;
import com.civichub.ai.product.dto.request.ImageContextSuggestionRequest;
import com.civichub.ai.product.dto.request.ResolutionSummarySuggestionRequest;
import com.civichub.ai.product.dto.response.ImageContextSuggestionResponse;
import com.civichub.ai.product.dto.response.TextSuggestionResponse;

public interface ProductAIService {

    TextSuggestionResponse improveReportDescription(DescriptionSuggestionRequest request);

    ImageContextSuggestionResponse describeImageContext(ImageContextSuggestionRequest request);

    TextSuggestionResponse improveResolutionSummary(ResolutionSummarySuggestionRequest request);
}
