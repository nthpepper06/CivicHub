package com.civichub.audit.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.audit.entity.AuditLog;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.audit.mapper.AuditLogMapper;
import com.civichub.audit.repository.AuditLogRepository;
import com.civichub.category.entity.Category;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class AuditServiceImplTest {

    @Mock
    private AuditLogRepository auditLogRepository;

    @Mock
    private UserRepository userRepository;

    private AuditServiceImpl auditService;

    @BeforeEach
    void setUp() {
        auditService = new AuditServiceImpl(
                auditLogRepository,
                userRepository,
                new AuditLogMapper(),
                new ObjectMapper());
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void recordCategoryCreationShouldStoreActorAndSafeEntitySnapshot() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Category category = category(1L, "Environment", true);

        auditService.recordCategoryCreated(category);

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.CATEGORY_CREATED);
        assertThat(auditLog.getEntityType()).isEqualTo(AuditEntityType.CATEGORY);
        assertThat(auditLog.getEntityId()).isEqualTo(1L);
        assertThat(auditLog.getActorId()).isEqualTo(7L);
        assertThat(auditLog.getActorName()).isEqualTo("Admin User");
        assertThat(auditLog.getActorRole()).isEqualTo(UserRole.ADMIN);
        assertThat(auditLog.getOldValues()).isNull();
        assertThat(auditLog.getNewValues())
                .contains("\"name\":\"Environment\"")
                .contains("\"isActive\":true")
                .doesNotContain("password")
                .doesNotContain("reports");
    }

    @Test
    void recordCategoryUpdateShouldStoreOldAndNewSafeValues() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Category category = category(1L, "New Category", true);
        Map<String, Object> oldValues = new LinkedHashMap<>();
        oldValues.put("name", "Old Category");
        oldValues.put("description", "Old description");
        oldValues.put("icon", "old");
        oldValues.put("isActive", true);

        auditService.recordCategoryUpdated(category, oldValues);

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.CATEGORY_UPDATED);
        assertThat(auditLog.getOldValues()).contains("\"name\":\"Old Category\"");
        assertThat(auditLog.getNewValues()).contains("\"name\":\"New Category\"");
    }

    @Test
    void recordCategoryActivationAndDeactivationShouldUseSpecificActions() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Category category = category(1L, "Environment", true);

        auditService.recordCategoryStatusChanged(category, false, true);

        assertThat(savedAuditLog().getAction()).isEqualTo(AuditAction.CATEGORY_ACTIVATED);
    }

    @Test
    void recordDepartmentCreationAndUpdateShouldUseDepartmentEntityType() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Department department = department(2L, "Urban Services", true);

        auditService.recordDepartmentCreated(department);

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.DEPARTMENT_CREATED);
        assertThat(auditLog.getEntityType()).isEqualTo(AuditEntityType.DEPARTMENT);
        assertThat(auditLog.getNewValues()).contains("\"name\":\"Urban Services\"");
    }

    @Test
    void recordDepartmentStatusChangeShouldUseActivationSpecificAction() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Department department = department(2L, "Urban Services", false);

        auditService.recordDepartmentStatusChanged(department, true, false);

        assertThat(savedAuditLog().getAction()).isEqualTo(AuditAction.DEPARTMENT_DEACTIVATED);
    }

    @Test
    void recordReportAssignmentShouldCaptureOldNullAndNewDepartment() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));
        Department department = department(2L, "Urban Services", true);

        auditService.recordReportAssignment(99L, "Broken street light", null, department);

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.REPORT_ASSIGNED);
        assertThat(auditLog.getEntityType()).isEqualTo(AuditEntityType.REPORT);
        assertThat(auditLog.getOldValues()).contains("\"departmentId\":null", "\"departmentName\":null");
        assertThat(auditLog.getNewValues()).contains("\"departmentId\":2", "\"departmentName\":\"Urban Services\"");
    }

    @Test
    void recordReportReassignmentShouldCaptureOldAndNewDepartment() {
        authenticate(7L, UserRole.ADMIN);
        when(userRepository.findById(7L)).thenReturn(Optional.of(actor(UserRole.ADMIN)));

        auditService.recordReportAssignment(
                99L,
                "Broken street light",
                department(1L, "Old Department", true),
                department(2L, "New Department", true));

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.REPORT_REASSIGNED);
        assertThat(auditLog.getOldValues()).contains("\"departmentId\":1", "\"departmentName\":\"Old Department\"");
        assertThat(auditLog.getNewValues()).contains("\"departmentId\":2", "\"departmentName\":\"New Department\"");
    }

    @Test
    void recordReportStatusChangeShouldCaptureOldAndNewStatus() {
        authenticate(8L, UserRole.STAFF);
        when(userRepository.findById(8L)).thenReturn(Optional.of(actor(UserRole.STAFF)));

        auditService.recordReportStatusChanged(99L, "Broken street light", ReportStatus.PENDING, ReportStatus.RECEIVED);

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.REPORT_STATUS_CHANGED);
        assertThat(auditLog.getOldValues()).contains("\"status\":\"PENDING\"");
        assertThat(auditLog.getNewValues()).contains("\"status\":\"RECEIVED\"");
        assertThat(auditLog.getActorRole()).isEqualTo(UserRole.STAFF);
    }

    @Test
    void recordReportCancellationShouldCapturePendingToCancelled() {
        authenticate(9L, UserRole.CITIZEN);
        when(userRepository.findById(9L)).thenReturn(Optional.of(actor(UserRole.CITIZEN)));

        auditService.recordReportCancelled(99L, "Broken street light");

        AuditLog auditLog = savedAuditLog();
        assertThat(auditLog.getAction()).isEqualTo(AuditAction.REPORT_CANCELLED);
        assertThat(auditLog.getOldValues()).contains("\"status\":\"PENDING\"");
        assertThat(auditLog.getNewValues()).contains("\"status\":\"CANCELLED\"");
    }

    @Test
    void listShouldValidateDateRange() {
        LocalDateTime createdFrom = LocalDateTime.parse("2026-01-02T00:00:00");
        LocalDateTime createdTo = LocalDateTime.parse("2026-01-01T00:00:00");

        assertThatThrownBy(() -> auditService.getAuditLogs(
                0,
                20,
                null,
                null,
                null,
                null,
                null,
                createdFrom,
                createdTo,
                null,
                null,
                null))
                .isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void listShouldCapPageSizeAndFallbackUnsafeSort() {
        when(auditLogRepository.findAll(anyAuditSpecification(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        auditService.getAuditLogs(0, 500, null, null, null, null, null, null, null, null, "bad", "ASC");

        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        verify(auditLogRepository).findAll(anyAuditSpecification(), captor.capture());
        assertThat(captor.getValue().getPageSize()).isEqualTo(100);
        assertThat(captor.getValue().getSort().getOrderFor("createdAt").isAscending()).isTrue();
    }

    @Test
    void missingDetailShouldReturnNotFound() {
        when(auditLogRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> auditService.getAuditLog(404L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    private AuditLog savedAuditLog() {
        ArgumentCaptor<AuditLog> captor = ArgumentCaptor.forClass(AuditLog.class);
        verify(auditLogRepository).save(captor.capture());
        return captor.getValue();
    }

    private void authenticate(Long userId, UserRole role) {
        CivicHubUserPrincipal principal = new CivicHubUserPrincipal(
                userId,
                "user@example.com",
                "encoded",
                role,
                true);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }

    private Specification<AuditLog> anyAuditSpecification() {
        return any();
    }

    private User actor(UserRole role) {
        return User.builder()
                .id(7L)
                .fullName(role == UserRole.STAFF ? "Staff User" : role == UserRole.CITIZEN ? "Citizen User" : "Admin User")
                .email("actor@example.com")
                .password("encoded")
                .role(role)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }

    private Category category(Long id, String name, boolean active) {
        return Category.builder()
                .id(id)
                .name(name)
                .description("Safe description")
                .icon("icon")
                .isActive(active)
                .build();
    }

    private Department department(Long id, String name, boolean active) {
        return Department.builder()
                .id(id)
                .name(name)
                .description("Safe description")
                .isActive(active)
                .build();
    }
}
