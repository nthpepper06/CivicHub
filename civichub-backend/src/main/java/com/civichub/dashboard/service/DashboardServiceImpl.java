package com.civichub.dashboard.service;

import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DashboardSummaryResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
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
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;
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
public class DashboardServiceImpl implements DashboardService {

    private static final int DEFAULT_RECENT_SIZE = 10;
    private static final int MAX_RECENT_SIZE = 50;

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final CategoryRepository categoryRepository;

    @Override
    @Transactional(readOnly = true)
    public DashboardSummaryResponse getAdminSummary() {
        ReportStatusStatisticResponse reportCounts = reportRepository.countReportsByStatus();
        return DashboardSummaryResponse.builder()
                .totalReports(reportCounts.getTotalReports())
                .pendingReports(reportCounts.getPendingReports())
                .receivedReports(reportCounts.getReceivedReports())
                .inProgressReports(reportCounts.getInProgressReports())
                .resolvedReports(reportCounts.getResolvedReports())
                .rejectedReports(reportCounts.getRejectedReports())
                .cancelledReports(reportCounts.getCancelledReports())
                .totalCitizens(userRepository.countByRole(UserRole.CITIZEN))
                .totalStaff(userRepository.countByRole(UserRole.STAFF))
                .totalDepartments(departmentRepository.count())
                .totalCategories(categoryRepository.count())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<CategoryStatisticResponse> getCategoryStatistics() {
        return reportRepository.countReportsByCategory();
    }

    @Override
    @Transactional(readOnly = true)
    public List<DepartmentStatisticResponse> getDepartmentStatistics() {
        return reportRepository.countReportsByDepartment();
    }

    @Override
    @Transactional(readOnly = true)
    public List<MonthlyStatisticResponse> getMonthlyStatistics(int year) {
        Map<Integer, MonthlyStatisticResponse> monthlyStatistics = new LinkedHashMap<>();
        IntStream.rangeClosed(1, 12)
                .forEach(month -> monthlyStatistics.put(month, MonthlyStatisticResponse.builder()
                        .month(month)
                        .totalReports(0L)
                        .resolvedReports(0L)
                        .build()));

        reportRepository.countReportsByMonth(year)
                .forEach(statistic -> monthlyStatistics.put(statistic.getMonth(), statistic));
        return List.copyOf(monthlyStatistics.values());
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportSummaryResponse> getAdminRecentReports(int size) {
        return toPageResponse(reportRepository.findRecentReportSummaries(recentPageable(size)));
    }

    @Override
    @Transactional(readOnly = true)
    public StaffDashboardSummaryResponse getStaffSummary() {
        return reportRepository.countReportsByStatusAndDepartmentId(getCurrentStaffDepartmentId());
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportSummaryResponse> getStaffRecentReports(int size) {
        Long departmentId = getCurrentStaffDepartmentId();
        return toPageResponse(reportRepository.findRecentReportSummariesByDepartmentId(
                departmentId,
                recentPageable(size)));
    }

    private Long getCurrentStaffDepartmentId() {
        User user = userRepository.findById(currentPrincipal().getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        if (user.getDepartment() == null) {
            throw new InvalidReportStateException("Staff user has no department");
        }
        Long departmentId = user.getDepartment().getId();
        Department department = departmentRepository.findById(departmentId)
                .orElseThrow(() -> new InvalidReportStateException("Staff department is unavailable"));
        if (!department.isActive()) {
            throw new InvalidReportStateException("Staff department is inactive");
        }
        return departmentId;
    }

    private CivicHubUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CivicHubUserPrincipal principal)) {
            throw new ResourceNotFoundException("Current user not found");
        }
        return principal;
    }

    private Pageable recentPageable(int size) {
        int normalizedSize = size <= 0 ? DEFAULT_RECENT_SIZE : Math.min(size, MAX_RECENT_SIZE);
        return PageRequest.of(0, normalizedSize, Sort.by(Sort.Direction.DESC, "createdAt"));
    }

    private PageResponse<ReportSummaryResponse> toPageResponse(Page<ReportSummaryResponse> page) {
        return PageResponse.<ReportSummaryResponse>builder()
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
