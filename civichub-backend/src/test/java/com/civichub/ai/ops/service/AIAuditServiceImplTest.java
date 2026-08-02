package com.civichub.ai.ops.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIUsage;
import com.civichub.ai.ops.entity.AIExecutionAudit;
import com.civichub.ai.ops.model.AIExecutionRecord;
import com.civichub.ai.ops.model.AIExecutionStatus;
import com.civichub.ai.ops.repository.AIExecutionAuditRepository;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Mockito;
import org.springframework.data.domain.Pageable;

class AIAuditServiceImplTest {

    private final AIExecutionAuditRepository repository = Mockito.mock(AIExecutionAuditRepository.class);
    private final AIUsageMetricsService metricsService = Mockito.mock(AIUsageMetricsService.class);
    private final AIAuditServiceImpl service = new AIAuditServiceImpl(
            repository,
            metricsService,
            new AIProperties(),
            new AITokenEstimator());

    @Test
    void persistsExecutionMetadataWithoutSensitivePromptText() {
        AIExecutionRecord record = AIExecutionRecord.builder()
                .request(AIRequest.builder()
                        .correlationId("req-1")
                        .taskType("REPORT_SUMMARY")
                        .templateId("REPORT_SUMMARY_V1")
                        .templateVersion("v1")
                        .outputSchemaId("report_summary")
                        .outputSchemaVersion("v1")
                        .systemContent("secret system prompt")
                        .userContent("raw citizen description")
                        .build())
                .response(AIResponse.builder()
                        .provider("OPENAI")
                        .model("gpt-test")
                        .usage(AIUsage.builder().inputTokens(10).outputTokens(4).totalTokens(14).build())
                        .build())
                .status(AIExecutionStatus.SUCCESS)
                .provider("OPENAI")
                .model("gpt-test")
                .latencyMs(42)
                .build();

        service.record(record);

        ArgumentCaptor<AIExecutionAudit> captor = ArgumentCaptor.forClass(AIExecutionAudit.class);
        verify(repository).save(captor.capture());
        verify(metricsService).record(record);
        AIExecutionAudit audit = captor.getValue();
        assertThat(audit.getCorrelationId()).isEqualTo("req-1");
        assertThat(audit.getTaskType()).isEqualTo("REPORT_SUMMARY");
        assertThat(audit.getTemplateId()).isEqualTo("REPORT_SUMMARY_V1");
        assertThat(audit.getPromptTokens()).isEqualTo(10);
        assertThat(audit.toString()).doesNotContain("raw citizen description");
    }

    @Test
    void recentCapsRequestedLimit() {
        when(repository.findAllByOrderByCreatedAtDesc(Mockito.any(Pageable.class))).thenReturn(List.of());

        assertThat(service.recent(500)).isEmpty();

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(repository).findAllByOrderByCreatedAtDesc(captor.capture());
        assertThat(captor.getValue().getPageSize()).isEqualTo(100);
    }
}
