package com.civichub.ai.ops.service;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIUsage;
import com.civichub.ai.ops.dto.AIRecentExecutionResponse;
import com.civichub.ai.ops.entity.AIExecutionAudit;
import com.civichub.ai.ops.model.AIExecutionRecord;
import com.civichub.ai.ops.repository.AIExecutionAuditRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataAccessException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class AIAuditServiceImpl implements AIAuditService {

    private final AIExecutionAuditRepository repository;
    private final AIUsageMetricsService metricsService;
    private final AIProperties properties;
    private final AITokenEstimator tokenEstimator;

    @Override
    public void record(AIExecutionRecord record) {
        metricsService.record(record);
        try {
            repository.save(toEntity(record));
        } catch (DataAccessException exception) {
            log.warn(
                    "ai_audit_persist_failed correlationId={} taskType={} provider={} errorCategory={}",
                    correlationId(record),
                    taskType(record),
                    record.getProvider(),
                    exception.getClass().getSimpleName());
        }
    }

    @Override
    public List<AIRecentExecutionResponse> recent(int limit) {
        int size = Math.max(1, Math.min(limit, 100));
        return repository.findAllByOrderByCreatedAtDesc(PageRequest.of(0, size)).stream()
                .map(this::toResponse)
                .toList();
    }

    private AIExecutionAudit toEntity(AIExecutionRecord record) {
        AIRequest request = record.getRequest();
        AIResponse response = record.getResponse();
        AIUsage usage = response == null ? null : response.getUsage();
        return AIExecutionAudit.builder()
                .requestId(correlationId(record))
                .correlationId(correlationId(record))
                .taskType(taskType(record))
                .provider(record.getProvider())
                .model(record.getModel())
                .templateId(request == null ? null : request.getTemplateId())
                .templateVersion(request == null ? null : request.getTemplateVersion())
                .schemaId(request == null ? null : request.getOutputSchemaId())
                .schemaVersion(request == null ? null : request.getOutputSchemaVersion())
                .status(record.getStatus().name())
                .errorCode(record.getErrorCode())
                .latencyMs(record.getLatencyMs())
                .promptTokens(promptTokens(record, usage))
                .completionTokens(completionTokens(record, usage))
                .totalTokens(totalTokens(record, usage))
                .estimatedCost(usage == null ? null : cost(usage))
                .build();
    }

    private AIRecentExecutionResponse toResponse(AIExecutionAudit audit) {
        return AIRecentExecutionResponse.builder()
                .id(audit.getId())
                .requestId(audit.getRequestId())
                .correlationId(audit.getCorrelationId())
                .taskType(audit.getTaskType())
                .provider(audit.getProvider())
                .model(audit.getModel())
                .templateId(audit.getTemplateId())
                .templateVersion(audit.getTemplateVersion())
                .schemaId(audit.getSchemaId())
                .schemaVersion(audit.getSchemaVersion())
                .status(audit.getStatus())
                .errorCode(audit.getErrorCode())
                .latencyMs(audit.getLatencyMs())
                .totalTokens(audit.getTotalTokens())
                .estimatedCost(audit.getEstimatedCost())
                .createdAt(audit.getCreatedAt())
                .build();
    }

    private String correlationId(AIExecutionRecord record) {
        return record.getRequest() == null ? null : record.getRequest().getCorrelationId();
    }

    private String taskType(AIExecutionRecord record) {
        return record.getRequest() == null ? null : record.getRequest().getTaskType();
    }

    private double cost(AIUsage usage) {
        double input = usage.getInputTokens() == null ? 0 : usage.getInputTokens();
        double output = usage.getOutputTokens() == null ? 0 : usage.getOutputTokens();
        return input / 1000.0 * properties.getInputTokenCostPerThousand()
                + output / 1000.0 * properties.getOutputTokenCostPerThousand();
    }

    private Integer promptTokens(AIExecutionRecord record, AIUsage usage) {
        if (usage != null && usage.getInputTokens() != null) {
            return usage.getInputTokens();
        }
        AIRequest request = record.getRequest();
        return request == null
                ? 0
                : tokenEstimator.estimate(request.getSystemContent())
                        + tokenEstimator.estimate(request.getUserContent());
    }

    private Integer completionTokens(AIExecutionRecord record, AIUsage usage) {
        if (usage != null && usage.getOutputTokens() != null) {
            return usage.getOutputTokens();
        }
        AIResponse response = record.getResponse();
        return response == null ? 0 : tokenEstimator.estimate(response.getOutput());
    }

    private Integer totalTokens(AIExecutionRecord record, AIUsage usage) {
        if (usage != null && usage.getTotalTokens() != null) {
            return usage.getTotalTokens();
        }
        return promptTokens(record, usage) + completionTokens(record, usage);
    }
}
