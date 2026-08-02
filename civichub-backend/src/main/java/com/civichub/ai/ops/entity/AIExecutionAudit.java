package com.civichub.ai.ops.entity;

import com.civichub.common.BaseEntity;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(
        name = "ai_execution_audits",
        indexes = {
                @Index(name = "idx_ai_execution_audits_created_at", columnList = "created_at"),
                @Index(name = "idx_ai_execution_audits_task_created_at", columnList = "task_type, created_at"),
                @Index(name = "idx_ai_execution_audits_provider_created_at", columnList = "provider, created_at"),
                @Index(name = "idx_ai_execution_audits_correlation_id", columnList = "correlation_id")
        })
@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode(callSuper = false)
public class AIExecutionAudit extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "request_id", length = 100)
    private String requestId;

    @Column(name = "correlation_id", length = 100)
    private String correlationId;

    @Column(name = "task_type", length = 80)
    private String taskType;

    @Column(length = 50)
    private String provider;

    @Column(length = 120)
    private String model;

    @Column(name = "template_id", length = 120)
    private String templateId;

    @Column(name = "template_version", length = 40)
    private String templateVersion;

    @Column(name = "schema_id", length = 120)
    private String schemaId;

    @Column(name = "schema_version", length = 40)
    private String schemaVersion;

    @Column(nullable = false, length = 30)
    private String status;

    @Column(name = "error_code", length = 80)
    private String errorCode;

    @Column(name = "latency_ms")
    private Long latencyMs;

    @Column(name = "prompt_tokens")
    private Integer promptTokens;

    @Column(name = "completion_tokens")
    private Integer completionTokens;

    @Column(name = "total_tokens")
    private Integer totalTokens;

    @Column(name = "estimated_cost")
    private Double estimatedCost;
}
