package com.civichub.ai.service;

import com.civichub.ai.dto.request.ImageContextAIRequest;
import com.civichub.ai.dto.request.ReportSummaryAIRequest;
import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;

public interface InternalAIUseCaseService {

    ReportSummaryAIResponse summarizeReport(ReportSummaryAIRequest request);

    ImageContextAIResponse describeImageContext(ImageContextAIRequest request);
}
