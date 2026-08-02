package com.civichub.ai.product.controller;

import com.civichub.ai.product.dto.request.DescriptionSuggestionRequest;
import com.civichub.ai.product.dto.request.ImageContextSuggestionRequest;
import com.civichub.ai.product.dto.request.ResolutionSummarySuggestionRequest;
import com.civichub.ai.product.dto.response.ImageContextSuggestionResponse;
import com.civichub.ai.product.dto.response.TextSuggestionResponse;
import com.civichub.ai.product.service.ProductAIService;
import com.civichub.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class ProductAIController {

    private final ProductAIService productAIService;

    @PostMapping("/reports/description-suggestion")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<TextSuggestionResponse>> improveReportDescription(
            @Valid @RequestBody DescriptionSuggestionRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Description suggestion generated",
                productAIService.improveReportDescription(request)));
    }

    @PostMapping("/reports/image-context")
    @PreAuthorize("hasRole('CITIZEN')")
    public ResponseEntity<ApiResponse<ImageContextSuggestionResponse>> describeImageContext(
            @Valid @RequestBody ImageContextSuggestionRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Image context suggestion generated",
                productAIService.describeImageContext(request)));
    }

    @PostMapping("/staff/resolution-summary-suggestion")
    @PreAuthorize("hasRole('STAFF')")
    public ResponseEntity<ApiResponse<TextSuggestionResponse>> improveResolutionSummary(
            @Valid @RequestBody ResolutionSummarySuggestionRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Resolution summary suggestion generated",
                productAIService.improveResolutionSummary(request)));
    }
}
