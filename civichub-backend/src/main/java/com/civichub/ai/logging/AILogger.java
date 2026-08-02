package com.civichub.ai.logging;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class AILogger {

    public void success(String provider, long latencyMs, AIRequest request, AIResponse response) {
        Integer totalTokens = response == null || response.getUsage() == null
                ? null
                : response.getUsage().getTotalTokens();
        log.info(
                "ai_request requestId={} correlationId={} taskType={} templateId={} schemaId={} provider={} model={} latencyMs={} success=true totalTokens={}",
                request == null ? null : request.getCorrelationId(),
                request == null ? null : request.getCorrelationId(),
                request == null ? null : request.getTaskType(),
                request == null ? null : request.getTemplateId(),
                request == null ? null : request.getOutputSchemaId(),
                provider,
                response == null ? null : response.getModel(),
                latencyMs,
                totalTokens);
    }

    public void failure(String provider, long latencyMs, AIRequest request, String code) {
        log.warn(
                "ai_request requestId={} correlationId={} taskType={} templateId={} schemaId={} provider={} model={} latencyMs={} success=false errorCode={}",
                request == null ? null : request.getCorrelationId(),
                request == null ? null : request.getCorrelationId(),
                request == null ? null : request.getTaskType(),
                request == null ? null : request.getTemplateId(),
                request == null ? null : request.getOutputSchemaId(),
                provider,
                request == null ? null : request.getModel(),
                latencyMs,
                code);
    }

    public void pipelineStage(String requestId, String provider, String stage, long latencyMs, boolean success) {
        log.info(
                "ai_pipeline requestId={} provider={} stage={} latencyMs={} success={}",
                requestId,
                provider,
                stage,
                latencyMs,
                success);
    }

    public void pipelineFailure(String requestId, String provider, String stage, long latencyMs, String code) {
        log.warn(
                "ai_pipeline requestId={} provider={} stage={} latencyMs={} success=false errorCode={}",
                requestId,
                provider,
                stage,
                latencyMs,
                code);
    }

    public void taskSuccess(
            String requestId,
            String taskType,
            String templateId,
            String templateVersion,
            String outputSchema,
            String provider,
            String model,
            long latencyMs) {
        log.info(
                "ai_task requestId={} taskType={} templateId={} templateVersion={} outputSchema={} provider={} model={} latencyMs={} success=true",
                requestId,
                taskType,
                templateId,
                templateVersion,
                outputSchema,
                provider,
                model,
                latencyMs);
    }

    public void taskFailure(
            String requestId,
            String taskType,
            String templateId,
            String templateVersion,
            String outputSchema,
            String provider,
            String model,
            long latencyMs,
            String code) {
        log.warn(
                "ai_task requestId={} taskType={} templateId={} templateVersion={} outputSchema={} provider={} model={} latencyMs={} success=false errorCode={}",
                requestId,
                taskType,
                templateId,
                templateVersion,
                outputSchema,
                provider,
                model,
                latencyMs,
                code);
    }
}
