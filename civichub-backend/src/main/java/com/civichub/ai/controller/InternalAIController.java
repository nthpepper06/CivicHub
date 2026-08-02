package com.civichub.ai.controller;

import com.civichub.ai.dto.request.ImageContextAIRequest;
import com.civichub.ai.dto.request.ReportSummaryAIRequest;
import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;
import com.civichub.ai.service.InternalAIUseCaseService;
import com.civichub.common.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/ai")
@RequiredArgsConstructor
public class InternalAIController {

    private final InternalAIUseCaseService internalAIUseCaseService;

    @PostMapping("/report-summary")
    public ResponseEntity<ApiResponse<ReportSummaryAIResponse>> summarizeReport(
            @Valid @RequestBody ReportSummaryAIRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Report summary generated",
                internalAIUseCaseService.summarizeReport(request)));
    }

    @PostMapping("/image-context")
    public ResponseEntity<ApiResponse<ImageContextAIResponse>> imageContext(
            @Valid @RequestBody ImageContextAIRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Image context generated",
                internalAIUseCaseService.describeImageContext(request)));
    }
}
