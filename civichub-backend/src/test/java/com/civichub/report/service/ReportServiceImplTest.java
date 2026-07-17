package com.civichub.report.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.category.entity.Category;
import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.report.dto.request.ReportCreateRequest;
import com.civichub.report.dto.request.ReportDepartmentAssignRequest;
import com.civichub.report.dto.request.ReportStatusUpdateRequest;
import com.civichub.report.dto.request.ReportUpdateRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.entity.Report;
import com.civichub.report.mapper.ReportMapper;
import com.civichub.report.repository.ReportRepository;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class ReportServiceImplTest {

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private ReportMapper reportMapper;

    private ReportServiceImpl reportService;

    @BeforeEach
    void setUp() {
        reportService = new ReportServiceImpl(
                reportRepository,
                userRepository,
                categoryRepository,
                departmentRepository,
                reportMapper);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void createReportShouldUseAuthenticatedUserSetPendingTrimFieldsAndStoreImagesInOrder() {
        authenticate(1L, UserRole.CITIZEN);
        User citizen = citizen(1L);
        Category category = category(true);
        ReportCreateRequest request = createRequest(List.of(" https://a.test/1.png ", "https://a.test/2.png"));

        when(userRepository.findById(1L)).thenReturn(Optional.of(citizen));
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category));
        when(reportRepository.save(any(Report.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(reportMapper.toDetailResponse(any(Report.class))).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.createReport(request);

        ArgumentCaptor<Report> captor = ArgumentCaptor.forClass(Report.class);
        verify(reportRepository).save(captor.capture());
        Report saved = captor.getValue();
        assertThat(saved.getUser()).isEqualTo(citizen);
        assertThat(saved.getTitle()).isEqualTo("Broken street light");
        assertThat(saved.getDescription()).isEqualTo("Street light is broken");
        assertThat(saved.getAddress()).isEqualTo("123 Main Street");
        assertThat(saved.getStatus()).isEqualTo(ReportStatus.PENDING);
        assertThat(saved.getDepartment()).isNull();
        assertThat(saved.getImages()).extracting("imageUrl")
                .containsExactly("https://a.test/1.png", "https://a.test/2.png");
        assertThat(saved.getImages()).extracting("displayOrder").containsExactly(0, 1);
    }

    @Test
    void createReportShouldRejectMissingCategory() {
        authenticate(1L, UserRole.CITIZEN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(citizen(1L)));
        when(categoryRepository.findById(10L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.createReport(createRequest(List.of())))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void createReportShouldRejectInactiveCategory() {
        authenticate(1L, UserRole.CITIZEN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(citizen(1L)));
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category(false)));

        assertThatThrownBy(() -> reportService.createReport(createRequest(List.of())))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void createReportShouldRejectDuplicateImageUrlsAfterTrim() {
        authenticate(1L, UserRole.CITIZEN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(citizen(1L)));
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category(true)));

        assertThatThrownBy(() -> reportService.createReport(
                createRequest(List.of("https://a.test/1.png", " https://a.test/1.png "))))
                .isInstanceOf(InvalidReportStateException.class);
        verify(reportRepository, never()).save(any(Report.class));
    }

    @Test
    void getMyReportsShouldQueryOnlyCurrentUserReports() {
        authenticate(1L, UserRole.CITIZEN);
        when(reportRepository.findAll(anyReportSpecification(), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        reportService.getMyReports(0, 10, null, null, null, "createdAt", "DESC");

        verify(reportRepository).findAll(anyReportSpecification(), any(org.springframework.data.domain.Pageable.class));
    }

    @Test
    void getMyReportShouldReturnNotFoundForAnotherUserReport() {
        authenticate(1L, UserRole.CITIZEN);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.getMyReport(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void getMyReportShouldUseOwnershipSafeDetailLookup() {
        authenticate(1L, UserRole.CITIZEN);
        Report report = report(ReportStatus.PENDING, null);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L)).thenReturn(Optional.of(report));
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.getMyReport(99L);

        verify(reportRepository).findDetailByIdAndUserId(99L, 1L);
    }

    @Test
    void updateMyReportShouldSucceedOnlyForPendingOwnerReport() {
        authenticate(1L, UserRole.CITIZEN);
        Report report = report(ReportStatus.PENDING, null);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L)).thenReturn(Optional.of(report));
        when(categoryRepository.findById(10L)).thenReturn(Optional.of(category(true)));
        when(reportRepository.save(report)).thenReturn(report);
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.updateMyReport(99L, updateRequest());

        assertThat(report.getTitle()).isEqualTo("Updated title");
        assertThat(report.getStatus()).isEqualTo(ReportStatus.PENDING);
    }

    @Test
    void updateMyReportShouldRejectNonPendingReport() {
        authenticate(1L, UserRole.CITIZEN);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L))
                .thenReturn(Optional.of(report(ReportStatus.RECEIVED, null)));

        assertThatThrownBy(() -> reportService.updateMyReport(99L, updateRequest()))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void cancelMyReportShouldChangePendingToCancelled() {
        authenticate(1L, UserRole.CITIZEN);
        Report report = report(ReportStatus.PENDING, null);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L)).thenReturn(Optional.of(report));
        when(reportRepository.save(report)).thenReturn(report);
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.cancelMyReport(99L);

        assertThat(report.getStatus()).isEqualTo(ReportStatus.CANCELLED);
    }

    @Test
    void cancelMyReportShouldRejectNonPendingReport() {
        authenticate(1L, UserRole.CITIZEN);
        when(reportRepository.findDetailByIdAndUserId(99L, 1L))
                .thenReturn(Optional.of(report(ReportStatus.IN_PROGRESS, null)));

        assertThatThrownBy(() -> reportService.cancelMyReport(99L))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void staffWithoutDepartmentShouldBeRejectedSafely() {
        authenticate(2L, UserRole.STAFF);
        User staff = staff(2L, null);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff));

        assertThatThrownBy(() -> reportService.getStaffReports(0, 10, null, null, null, null, null, null))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void staffCannotAccessAnotherDepartmentReport() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findDetailByIdAndDepartmentId(99L, 5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.getStaffReport(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void staffDetailShouldUseDepartmentScopedDetailLookup() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        Report report = report(ReportStatus.RECEIVED, department);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findDetailByIdAndDepartmentId(99L, 5L)).thenReturn(Optional.of(report));
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.getStaffReport(99L);

        verify(reportRepository).findDetailByIdAndDepartmentId(99L, 5L);
    }

    @Test
    void inactiveStaffDepartmentShouldBeRejectedSafely() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        Department inactiveDepartment = department(5L, false);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(inactiveDepartment));

        assertThatThrownBy(() -> reportService.getStaffReports(0, 10, null, null, null, null, null, null))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void invalidStaffDateRangeShouldBeRejected() {
        LocalDateTime createdFrom = LocalDateTime.parse("2026-01-02T00:00:00");
        LocalDateTime createdTo = LocalDateTime.parse("2026-01-01T00:00:00");

        assertThatThrownBy(() -> reportService.getStaffReports(
                0,
                10,
                null,
                null,
                null,
                null,
                createdFrom,
                createdTo))
                .isInstanceOf(IllegalArgumentException.class);
        verify(userRepository, never()).findById(any());
    }

    @Test
    void validStatusTransitionShouldSucceed() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        Report report = report(ReportStatus.RECEIVED, department);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findDetailByIdAndDepartmentId(99L, 5L)).thenReturn(Optional.of(report));
        when(reportRepository.save(report)).thenReturn(report);
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.updateStaffReportStatus(99L, new ReportStatusUpdateRequest(ReportStatus.IN_PROGRESS));

        assertThat(report.getStatus()).isEqualTo(ReportStatus.IN_PROGRESS);
    }

    @Test
    void invalidStatusTransitionShouldReturnConflictDomainException() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findDetailByIdAndDepartmentId(99L, 5L))
                .thenReturn(Optional.of(report(ReportStatus.PENDING, department)));

        assertThatThrownBy(() -> reportService.updateStaffReportStatus(
                99L,
                new ReportStatusUpdateRequest(ReportStatus.RESOLVED)))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void terminalStatusCannotTransition() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findDetailByIdAndDepartmentId(99L, 5L))
                .thenReturn(Optional.of(report(ReportStatus.RESOLVED, department)));

        assertThatThrownBy(() -> reportService.updateStaffReportStatus(
                99L,
                new ReportStatusUpdateRequest(ReportStatus.REJECTED)))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void adminShouldAssignActiveDepartmentAndPreserveStatus() {
        Report report = report(ReportStatus.PENDING, null);
        Department department = department(5L, true);
        when(reportRepository.findDetailById(99L)).thenReturn(Optional.of(report));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.save(report)).thenReturn(report);
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.assignDepartment(99L, new ReportDepartmentAssignRequest(5L));

        assertThat(report.getDepartment()).isEqualTo(department);
        assertThat(report.getStatus()).isEqualTo(ReportStatus.PENDING);
    }

    @Test
    void adminDetailShouldUseRelationshipLoadingLookup() {
        Report report = report(ReportStatus.PENDING, null);
        when(reportRepository.findDetailById(99L)).thenReturn(Optional.of(report));
        when(reportMapper.toDetailResponse(report)).thenReturn(ReportDetailResponse.builder().id(99L).build());

        reportService.getAdminReport(99L);

        verify(reportRepository).findDetailById(99L);
    }

    @Test
    void adminAssignShouldRejectMissingDepartment() {
        when(reportRepository.findDetailById(99L)).thenReturn(Optional.of(report(ReportStatus.PENDING, null)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> reportService.assignDepartment(99L, new ReportDepartmentAssignRequest(5L)))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void adminAssignShouldRejectInactiveDepartment() {
        when(reportRepository.findDetailById(99L)).thenReturn(Optional.of(report(ReportStatus.PENDING, null)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department(5L, false)));

        assertThatThrownBy(() -> reportService.assignDepartment(99L, new ReportDepartmentAssignRequest(5L)))
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void adminListShouldUseFilters() {
        when(reportRepository.findAll(anyReportSpecification(), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        reportService.getAdminReports(0, 10, "road", ReportStatus.PENDING, 10L, 5L, 1L,
                null, null, true, "title", "ASC");

        verify(reportRepository).findAll(anyReportSpecification(), any(org.springframework.data.domain.Pageable.class));
    }

    @Test
    void invalidAdminDateRangeShouldBeRejected() {
        LocalDateTime createdFrom = LocalDateTime.parse("2026-01-02T00:00:00");
        LocalDateTime createdTo = LocalDateTime.parse("2026-01-01T00:00:00");

        assertThatThrownBy(() -> reportService.getAdminReports(
                0,
                10,
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
        verify(reportRepository, never()).findAll(anyReportSpecification(), any(org.springframework.data.domain.Pageable.class));
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

    private Specification<Report> anyReportSpecification() {
        return any();
    }

    private ReportCreateRequest createRequest(List<String> imageUrls) {
        return new ReportCreateRequest(
                " Broken street light ",
                " Street light is broken ",
                " 123 Main Street ",
                BigDecimal.valueOf(10.1234567),
                BigDecimal.valueOf(106.1234567),
                10L,
                imageUrls);
    }

    private ReportUpdateRequest updateRequest() {
        return new ReportUpdateRequest(
                " Updated title ",
                " Updated description ",
                " Updated address ",
                null,
                null,
                10L,
                List.of("https://a.test/new.png"));
    }

    private User citizen(Long id) {
        return User.builder()
                .id(id)
                .fullName("Citizen")
                .email("citizen@example.com")
                .password("encoded")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }

    private User staff(Long id, Department department) {
        return User.builder()
                .id(id)
                .fullName("Staff")
                .email("staff@example.com")
                .password("encoded")
                .role(UserRole.STAFF)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .department(department)
                .build();
    }

    private Category category(boolean active) {
        return Category.builder()
                .id(10L)
                .name("Lighting")
                .isActive(active)
                .build();
    }

    private Department department(Long id, boolean active) {
        return Department.builder()
                .id(id)
                .name("Urban Services")
                .isActive(active)
                .build();
    }

    private Report report(ReportStatus status, Department department) {
        return Report.builder()
                .id(99L)
                .title("Report")
                .description("Description")
                .address("Address")
                .status(status)
                .category(category(true))
                .user(citizen(1L))
                .department(department)
                .priority(com.civichub.common.enums.Priority.MEDIUM)
                .build();
    }
}
