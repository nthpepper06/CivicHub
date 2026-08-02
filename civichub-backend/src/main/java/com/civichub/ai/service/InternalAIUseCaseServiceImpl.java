package com.civichub.ai.service;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.request.ImageContextAIRequest;
import com.civichub.ai.dto.request.ReportSummaryAIRequest;
import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;
import com.civichub.ai.execution.AITaskExecutionService;
import com.civichub.ai.output.AIOutputMapper;
import com.civichub.ai.output.AIOutputSchemaRegistry;
import com.civichub.ai.output.AIStructuredOutputDefinition;
import com.civichub.ai.task.AITaskRequest;
import com.civichub.ai.task.AITaskType;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

@Service
@RequiredArgsConstructor
public class InternalAIUseCaseServiceImpl implements InternalAIUseCaseService {

    private final AITaskExecutionService taskExecutionService;
    private final AIOutputMapper outputMapper;
    private final AIOutputSchemaRegistry outputSchemaRegistry;

    @Override
    public ReportSummaryAIResponse summarizeReport(ReportSummaryAIRequest request) {
        AIResponse response = taskExecutionService.executeText(AITaskRequest.builder()
                .taskType(AITaskType.REPORT_SUMMARY)
                .locale(request.getLocale())
                .reportId(request.getReportId())
                .variables(Map.of(
                        "title", request.getTitle(),
                        "description", request.getDescription()))
                .build());
        AIStructuredOutputDefinition schema = outputSchemaRegistry.resolve("report_summary", "v1");
        Map<String, Object> payload = outputMapper.mapJsonObject(response, schema);
        return ReportSummaryAIResponse.builder()
                .requestId(String.valueOf(response.getMetadata().get("correlationId")))
                .summary(String.valueOf(payload.get("summary")))
                .provider(response.getProvider())
                .model(response.getModel())
                .taskType(String.valueOf(response.getMetadata().get("taskType")))
                .templateId(String.valueOf(response.getMetadata().get("templateId")))
                .templateVersion(String.valueOf(response.getMetadata().get("templateVersion")))
                .outputSchemaId(schema.getSchemaId())
                .outputSchemaVersion(schema.getVersion())
                .build();
    }

    @Override
    public ImageContextAIResponse describeImageContext(ImageContextAIRequest request) {
        Map<String, String> variables = StringUtils.hasText(request.getLocation())
                ? Map.of("title", request.getTitle(), "location", request.getLocation())
                : Map.of("title", request.getTitle());
        AIResponse response = taskExecutionService.executeImage(AITaskRequest.builder()
                        .taskType(AITaskType.IMAGE_CONTEXT)
                        .locale(request.getLocale())
                        .reportId(request.getReportId())
                        .imageReference(request.getImageUrl())
                        .variables(variables)
                        .build())
                .getPayload();
        AIStructuredOutputDefinition schema = outputSchemaRegistry.resolve("image_context", "v1");
        Map<String, Object> payload = outputMapper.mapJsonObject(response, schema);
        return ImageContextAIResponse.builder()
                .requestId(String.valueOf(response.getMetadata().get("correlationId")))
                .context(String.valueOf(payload.get("context")))
                .provider(response.getProvider())
                .model(response.getModel())
                .taskType(String.valueOf(response.getMetadata().get("taskType")))
                .templateId(String.valueOf(response.getMetadata().get("templateId")))
                .templateVersion(String.valueOf(response.getMetadata().get("templateVersion")))
                .outputSchemaId(schema.getSchemaId())
                .outputSchemaVersion(schema.getVersion())
                .build();
    }
}
