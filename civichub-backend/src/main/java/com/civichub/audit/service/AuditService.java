package com.civichub.audit.service;

import com.civichub.audit.dto.response.AuditLogDetailResponse;
import com.civichub.audit.dto.response.AuditLogSummaryResponse;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.category.entity.Category;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.department.entity.Department;
import java.time.LocalDateTime;
import java.util.Map;

public interface AuditService {

    PageResponse<AuditLogSummaryResponse> getAuditLogs(
            int page,
            int size,
            AuditAction action,
            AuditEntityType entityType,
            Long entityId,
            Long actorId,
            UserRole actorRole,
            LocalDateTime createdFrom,
            LocalDateTime createdTo,
            String search,
            String sortBy,
            String direction);

    AuditLogDetailResponse getAuditLog(Long id);

    void recordCategoryCreated(Category category);

    void recordCategoryUpdated(Category category, Map<String, Object> oldValues);

    void recordCategoryStatusChanged(Category category, boolean oldActive, boolean newActive);

    void recordDepartmentCreated(Department department);

    void recordDepartmentUpdated(Department department, Map<String, Object> oldValues);

    void recordDepartmentStatusChanged(Department department, boolean oldActive, boolean newActive);

    void recordReportAssignment(Long reportId, String reportTitle, Department oldDepartment, Department newDepartment);

    void recordReportStatusChanged(Long reportId, String reportTitle, ReportStatus oldStatus, ReportStatus newStatus);

    void recordReportCancelled(Long reportId, String reportTitle);
}
