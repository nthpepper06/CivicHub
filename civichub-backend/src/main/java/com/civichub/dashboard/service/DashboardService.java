package com.civichub.dashboard.service;

import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DashboardSummaryResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import java.time.LocalDateTime;
import java.util.List;

public interface DashboardService {

    DashboardSummaryResponse getAdminSummary(LocalDateTime createdFrom, LocalDateTime createdTo);

    default DashboardSummaryResponse getAdminSummary() {
        return getAdminSummary(null, null);
    }

    List<CategoryStatisticResponse> getCategoryStatistics(LocalDateTime createdFrom, LocalDateTime createdTo);

    default List<CategoryStatisticResponse> getCategoryStatistics() {
        return getCategoryStatistics(null, null);
    }

    List<DepartmentStatisticResponse> getDepartmentStatistics(LocalDateTime createdFrom, LocalDateTime createdTo);

    default List<DepartmentStatisticResponse> getDepartmentStatistics() {
        return getDepartmentStatistics(null, null);
    }

    List<MonthlyStatisticResponse> getMonthlyStatistics(int year, LocalDateTime createdFrom, LocalDateTime createdTo);

    default List<MonthlyStatisticResponse> getMonthlyStatistics(int year) {
        return getMonthlyStatistics(year, null, null);
    }

    PageResponse<ReportSummaryResponse> getAdminRecentReports(int size);

    StaffDashboardSummaryResponse getStaffSummary();

    PageResponse<ReportSummaryResponse> getStaffRecentReports(int size);
}
