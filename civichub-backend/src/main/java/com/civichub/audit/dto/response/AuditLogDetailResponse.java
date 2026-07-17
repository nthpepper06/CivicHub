package com.civichub.audit.dto.response;

import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.common.enums.UserRole;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuditLogDetailResponse {

    private Long id;
    private AuditAction action;
    private AuditEntityType entityType;
    private Long entityId;
    private Long actorId;
    private String actorName;
    private UserRole actorRole;
    private String description;
    private String oldValues;
    private String newValues;
    private LocalDateTime createdAt;
    private String correlationId;
}
