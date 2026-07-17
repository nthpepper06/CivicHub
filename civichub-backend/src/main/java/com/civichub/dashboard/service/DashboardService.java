package com.civichub.dashboard.service;

import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DashboardSummaryResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import java.util.List;

public interface DashboardService {

    DashboardSummaryResponse getAdminSummary();

    List<CategoryStatisticResponse> getCategoryStatistics();

    List<DepartmentStatisticResponse> getDepartmentStatistics();

    List<MonthlyStatisticResponse> getMonthlyStatistics(int year);

    PageResponse<ReportSummaryResponse> getAdminRecentReports(int size);

    StaffDashboardSummaryResponse getStaffSummary();

    PageResponse<ReportSummaryResponse> getStaffRecentReports(int size);
}
