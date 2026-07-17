package com.civichub.audit.mapper;

import com.civichub.audit.dto.response.AuditLogDetailResponse;
import com.civichub.audit.dto.response.AuditLogSummaryResponse;
import com.civichub.audit.entity.AuditLog;
import org.springframework.stereotype.Component;

@Component
public class AuditLogMapper {

    public AuditLogSummaryResponse toSummaryResponse(AuditLog auditLog) {
        return AuditLogSummaryResponse.builder()
                .id(auditLog.getId())
                .action(auditLog.getAction())
                .entityType(auditLog.getEntityType())
                .entityId(auditLog.getEntityId())
                .actorId(auditLog.getActorId())
                .actorName(auditLog.getActorName())
                .actorRole(auditLog.getActorRole())
                .description(auditLog.getDescription())
                .createdAt(auditLog.getCreatedAt())
                .build();
    }

    public AuditLogDetailResponse toDetailResponse(AuditLog auditLog) {
        return AuditLogDetailResponse.builder()
                .id(auditLog.getId())
                .action(auditLog.getAction())
                .entityType(auditLog.getEntityType())
                .entityId(auditLog.getEntityId())
                .actorId(auditLog.getActorId())
                .actorName(auditLog.getActorName())
                .actorRole(auditLog.getActorRole())
                .description(auditLog.getDescription())
                .oldValues(auditLog.getOldValues())
                .newValues(auditLog.getNewValues())
                .createdAt(auditLog.getCreatedAt())
                .correlationId(auditLog.getCorrelationId())
                .build();
    }
}
