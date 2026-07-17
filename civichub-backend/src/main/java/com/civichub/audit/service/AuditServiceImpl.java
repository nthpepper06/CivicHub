package com.civichub.audit.service;

import com.civichub.audit.dto.response.AuditLogDetailResponse;
import com.civichub.audit.dto.response.AuditLogSummaryResponse;
import com.civichub.audit.entity.AuditLog;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.audit.mapper.AuditLogMapper;
import com.civichub.audit.repository.AuditLogRepository;
import com.civichub.audit.specification.AuditLogSpecification;
import com.civichub.category.entity.Category;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuditServiceImpl implements AuditService {

    private static final int DEFAULT_PAGE_SIZE = 20;
    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("createdAt", "action", "entityType", "actorName");

    private final AuditLogRepository auditLogRepository;
    private final UserRepository userRepository;
    private final AuditLogMapper auditLogMapper;
    private final ObjectMapper objectMapper;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<AuditLogSummaryResponse> getAuditLogs(
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
            String direction) {
        validateDateRange(createdFrom, createdTo);
        Page<AuditLog> auditLogs = auditLogRepository.findAll(
                AuditLogSpecification.filter(
                        action,
                        entityType,
                        entityId,
                        actorId,
                        actorRole,
                        createdFrom,
                        createdTo,
                        search),
                pageable(page, size, sortBy, direction));
        return toPageResponse(auditLogs.map(auditLogMapper::toSummaryResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public AuditLogDetailResponse getAuditLog(Long id) {
        return auditLogMapper.toDetailResponse(auditLogRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Audit log not found")));
    }

    @Override
    @Transactional
    public void recordCategoryCreated(Category category) {
        record(
                AuditAction.CATEGORY_CREATED,
                AuditEntityType.CATEGORY,
                category.getId(),
                "Category \"%s\" was created.".formatted(category.getName()),
                null,
                categorySnapshot(category));
    }

    @Override
    @Transactional
    public void recordCategoryUpdated(Category category, Map<String, Object> oldValues) {
        record(
                AuditAction.CATEGORY_UPDATED,
                AuditEntityType.CATEGORY,
                category.getId(),
                "Category \"%s\" was updated.".formatted(category.getName()),
                oldValues,
                categorySnapshot(category));
    }

    @Override
    @Transactional
    public void recordCategoryStatusChanged(Category category, boolean oldActive, boolean newActive) {
        if (oldActive == newActive) {
            return;
        }
        record(
                newActive ? AuditAction.CATEGORY_ACTIVATED : AuditAction.CATEGORY_DEACTIVATED,
                AuditEntityType.CATEGORY,
                category.getId(),
                "Category \"%s\" was %s.".formatted(category.getName(), newActive ? "activated" : "deactivated"),
                activeSnapshot(oldActive),
                activeSnapshot(newActive));
    }

    @Override
    @Transactional
    public void recordDepartmentCreated(Department department) {
        record(
                AuditAction.DEPARTMENT_CREATED,
                AuditEntityType.DEPARTMENT,
                department.getId(),
                "Department \"%s\" was created.".formatted(department.getName()),
                null,
                departmentSnapshot(department));
    }

    @Override
    @Transactional
    public void recordDepartmentUpdated(Department department, Map<String, Object> oldValues) {
        record(
                AuditAction.DEPARTMENT_UPDATED,
                AuditEntityType.DEPARTMENT,
                department.getId(),
                "Department \"%s\" was updated.".formatted(department.getName()),
                oldValues,
                departmentSnapshot(department));
    }

    @Override
    @Transactional
    public void recordDepartmentStatusChanged(Department department, boolean oldActive, boolean newActive) {
        if (oldActive == newActive) {
            return;
        }
        record(
                newActive ? AuditAction.DEPARTMENT_ACTIVATED : AuditAction.DEPARTMENT_DEACTIVATED,
                AuditEntityType.DEPARTMENT,
                department.getId(),
                "Department \"%s\" was %s.".formatted(department.getName(), newActive ? "activated" : "deactivated"),
                activeSnapshot(oldActive),
                activeSnapshot(newActive));
    }

    @Override
    @Transactional
    public void recordReportAssignment(Long reportId, String reportTitle, Department oldDepartment, Department newDepartment) {
        AuditAction action = oldDepartment == null ? AuditAction.REPORT_ASSIGNED : AuditAction.REPORT_REASSIGNED;
        record(
                action,
                AuditEntityType.REPORT,
                reportId,
                "Report \"%s\" was %s to department \"%s\"."
                        .formatted(reportTitle, oldDepartment == null ? "assigned" : "reassigned", newDepartment.getName()),
                departmentReferenceSnapshot(oldDepartment),
                departmentReferenceSnapshot(newDepartment));
    }

    @Override
    @Transactional
    public void recordReportStatusChanged(Long reportId, String reportTitle, ReportStatus oldStatus, ReportStatus newStatus) {
        record(
                AuditAction.REPORT_STATUS_CHANGED,
                AuditEntityType.REPORT,
                reportId,
                "Report \"%s\" status changed from %s to %s."
                        .formatted(reportTitle, oldStatus.name(), newStatus.name()),
                statusSnapshot(oldStatus),
                statusSnapshot(newStatus));
    }

    @Override
    @Transactional
    public void recordReportCancelled(Long reportId, String reportTitle) {
        record(
                AuditAction.REPORT_CANCELLED,
                AuditEntityType.REPORT,
                reportId,
                "Report \"%s\" was cancelled.".formatted(reportTitle),
                statusSnapshot(ReportStatus.PENDING),
                statusSnapshot(ReportStatus.CANCELLED));
    }

    private void record(
            AuditAction action,
            AuditEntityType entityType,
            Long entityId,
            String description,
            Map<String, Object> oldValues,
            Map<String, Object> newValues) {
        User actor = currentActor();
        auditLogRepository.save(AuditLog.builder()
                .action(action)
                .entityType(entityType)
                .entityId(entityId)
                .actorId(actor.getId())
                .actorName(actor.getFullName())
                .actorRole(actor.getRole())
                .description(description)
                .oldValues(toJson(oldValues))
                .newValues(toJson(newValues))
                .build());
    }

    private User currentActor() {
        CivicHubUserPrincipal principal = currentPrincipal();
        return userRepository.findById(principal.getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
    }

    private CivicHubUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CivicHubUserPrincipal principal)) {
            throw new ResourceNotFoundException("Current user not found");
        }
        return principal;
    }

    private String toJson(Map<String, Object> values) {
        if (values == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(values);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Unable to serialize audit values");
        }
    }

    public Map<String, Object> categorySnapshot(Category category) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("name", category.getName());
        snapshot.put("description", category.getDescription());
        snapshot.put("icon", category.getIcon());
        snapshot.put("isActive", category.isActive());
        return snapshot;
    }

    public Map<String, Object> departmentSnapshot(Department department) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("name", department.getName());
        snapshot.put("description", department.getDescription());
        snapshot.put("isActive", department.isActive());
        return snapshot;
    }

    private Map<String, Object> departmentReferenceSnapshot(Department department) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("departmentId", department == null ? null : department.getId());
        snapshot.put("departmentName", department == null ? null : department.getName());
        return snapshot;
    }

    private Map<String, Object> statusSnapshot(ReportStatus status) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("status", status.name());
        return snapshot;
    }

    private Map<String, Object> activeSnapshot(boolean active) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("isActive", active);
        return snapshot;
    }

    private void validateDateRange(LocalDateTime createdFrom, LocalDateTime createdTo) {
        if (createdFrom != null && createdTo != null && createdFrom.isAfter(createdTo)) {
            throw new IllegalArgumentException("Invalid date range");
        }
    }

    private Pageable pageable(int page, int size, String sortBy, String direction) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
        String safeSortBy = ALLOWED_SORT_FIELDS.contains(sortBy) ? sortBy : "createdAt";
        Sort.Direction safeDirection = "ASC".equalsIgnoreCase(direction) ? Sort.Direction.ASC : Sort.Direction.DESC;
        return PageRequest.of(normalizedPage, normalizedSize, Sort.by(safeDirection, safeSortBy));
    }

    private PageResponse<AuditLogSummaryResponse> toPageResponse(Page<AuditLogSummaryResponse> page) {
        return PageResponse.<AuditLogSummaryResponse>builder()
                .content(page.getContent())
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .first(page.isFirst())
                .last(page.isLast())
                .build();
    }
}
