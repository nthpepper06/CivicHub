package com.civichub.dashboard.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
import com.civichub.dashboard.dto.response.ReportStatusStatisticResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.repository.ReportRepository;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
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
import org.springframework.data.domain.Pageable;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class DashboardServiceImplTest {

    @Mock
    private ReportRepository reportRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private CategoryRepository categoryRepository;

    private DashboardServiceImpl dashboardService;

    @BeforeEach
    void setUp() {
        dashboardService = new DashboardServiceImpl(
                reportRepository,
                userRepository,
                departmentRepository,
                categoryRepository);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void adminSummaryShouldCombineReportAndMasterDataCounts() {
        when(reportRepository.countReportsByStatus())
                .thenReturn(new ReportStatusStatisticResponse(9, 1, 2, 3, 1, 1, 1));
        when(userRepository.countByRole(UserRole.CITIZEN)).thenReturn(11L);
        when(userRepository.countByRole(UserRole.STAFF)).thenReturn(4L);
        when(departmentRepository.count()).thenReturn(3L);
        when(categoryRepository.count()).thenReturn(7L);

        var response = dashboardService.getAdminSummary();

        assertThat(response.getTotalReports()).isEqualTo(9);
        assertThat(response.getPendingReports()).isEqualTo(1);
        assertThat(response.getReceivedReports()).isEqualTo(2);
        assertThat(response.getInProgressReports()).isEqualTo(3);
        assertThat(response.getResolvedReports()).isEqualTo(1);
        assertThat(response.getRejectedReports()).isEqualTo(1);
        assertThat(response.getCancelledReports()).isEqualTo(1);
        assertThat(response.getTotalCitizens()).isEqualTo(11);
        assertThat(response.getTotalStaff()).isEqualTo(4);
        assertThat(response.getTotalDepartments()).isEqualTo(3);
        assertThat(response.getTotalCategories()).isEqualTo(7);
    }

    @Test
    void monthlyStatisticsShouldAlwaysReturnTwelveMonthsAndFillMissingWithZero() {
        when(reportRepository.countReportsByMonth(2026))
                .thenReturn(List.of(
                        MonthlyStatisticResponse.builder()
                                .month(2)
                                .totalReports(5)
                                .resolvedReports(3)
                                .build(),
                        MonthlyStatisticResponse.builder()
                                .month(12)
                                .totalReports(1)
                                .resolvedReports(0)
                                .build()));

        List<MonthlyStatisticResponse> response = dashboardService.getMonthlyStatistics(2026);

        assertThat(response).hasSize(12);
        assertThat(response.get(0).getMonth()).isEqualTo(1);
        assertThat(response.get(0).getTotalReports()).isZero();
        assertThat(response.get(1).getTotalReports()).isEqualTo(5);
        assertThat(response.get(11).getTotalReports()).isEqualTo(1);
    }

    @Test
    void emptyMonthlyStatisticsShouldReturnZeroForAllMonths() {
        when(reportRepository.countReportsByMonth(2026)).thenReturn(List.of());

        List<MonthlyStatisticResponse> response = dashboardService.getMonthlyStatistics(2026);

        assertThat(response).hasSize(12);
        assertThat(response).allSatisfy(statistic -> {
            assertThat(statistic.getTotalReports()).isZero();
            assertThat(statistic.getResolvedReports()).isZero();
        });
    }

    @Test
    void staffSummaryShouldUseCurrentStaffDepartment() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.countReportsByStatusAndDepartmentId(5L))
                .thenReturn(new StaffDashboardSummaryResponse(1, 2, 3, 4, 5, 6, 21));

        StaffDashboardSummaryResponse response = dashboardService.getStaffSummary();

        assertThat(response.getTotalAssigned()).isEqualTo(21);
        verify(reportRepository).countReportsByStatusAndDepartmentId(5L);
    }

    @Test
    void staffRecentShouldFilterByCurrentStaffDepartmentAndCreatedAtDescending() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(reportRepository.findRecentReportSummariesByDepartmentId(any(), any()))
                .thenReturn(new PageImpl<>(List.of(ReportSummaryResponse.builder().id(99L).build())));

        var response = dashboardService.getStaffRecentReports(10);

        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(reportRepository).findRecentReportSummariesByDepartmentId(
                org.mockito.ArgumentMatchers.eq(5L),
                pageableCaptor.capture());
        assertThat(response.getContent()).extracting(ReportSummaryResponse::getId).containsExactly(99L);
        assertThat(pageableCaptor.getValue().getPageNumber()).isZero();
        assertThat(pageableCaptor.getValue().getSort().getOrderFor("createdAt").isDescending()).isTrue();
    }

    @Test
    void inactiveStaffDepartmentShouldBeRejected() {
        authenticate(2L, UserRole.STAFF);
        Department department = department(5L, true);
        when(userRepository.findById(2L)).thenReturn(Optional.of(staff(2L, department)));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department(5L, false)));

        assertThatThrownBy(() -> dashboardService.getStaffSummary())
                .isInstanceOf(InvalidReportStateException.class);
    }

    @Test
    void adminRecentShouldUseDefaultSizeWhenInvalidSizeProvided() {
        when(reportRepository.findRecentReportSummaries(any()))
                .thenReturn(new PageImpl<>(List.of()));

        dashboardService.getAdminRecentReports(0);

        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(reportRepository).findRecentReportSummaries(pageableCaptor.capture());
        assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(10);
        assertThat(pageableCaptor.getValue().getSort().getOrderFor("createdAt").isDescending()).isTrue();
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

    private Department department(Long id, boolean active) {
        return Department.builder()
                .id(id)
                .name("Urban Services")
                .isActive(active)
                .build();
    }
}
