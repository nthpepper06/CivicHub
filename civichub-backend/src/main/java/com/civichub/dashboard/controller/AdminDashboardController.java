package com.civichub.dashboard.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DashboardSummaryResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
import com.civichub.dashboard.service.DashboardService;
import com.civichub.report.dto.response.ReportSummaryResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import java.time.Year;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/dashboard")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "bearerAuth")
public class AdminDashboardController {

    private final DashboardService dashboardService;

    @Operation(summary = "Get admin dashboard summary")
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getSummary() {
        return ResponseEntity.ok(ApiResponse.success("Dashboard summary", dashboardService.getAdminSummary()));
    }

    @Operation(summary = "Get report statistics grouped by category")
    @GetMapping("/category")
    public ResponseEntity<ApiResponse<List<CategoryStatisticResponse>>> getCategoryStatistics() {
        return ResponseEntity.ok(ApiResponse.success(
                "Category statistics",
                dashboardService.getCategoryStatistics()));
    }

    @Operation(summary = "Get report statistics grouped by department")
    @GetMapping("/department")
    public ResponseEntity<ApiResponse<List<DepartmentStatisticResponse>>> getDepartmentStatistics() {
        return ResponseEntity.ok(ApiResponse.success(
                "Department statistics",
                dashboardService.getDepartmentStatistics()));
    }

    @Operation(summary = "Get monthly report statistics for a year")
    @GetMapping("/monthly")
    public ResponseEntity<ApiResponse<List<MonthlyStatisticResponse>>> getMonthlyStatistics(
            @RequestParam(required = false) Integer year) {
        int selectedYear = year == null ? Year.now().getValue() : year;
        return ResponseEntity.ok(ApiResponse.success(
                "Monthly statistics",
                dashboardService.getMonthlyStatistics(selectedYear)));
    }

    @Operation(summary = "Get recent reports for admin dashboard")
    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<PageResponse<ReportSummaryResponse>>> getRecentReports(
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success(
                "Recent reports",
                dashboardService.getAdminRecentReports(size)));
    }
}
