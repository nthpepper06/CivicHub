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
import java.time.LocalDateTime;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
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
    public ResponseEntity<ApiResponse<DashboardSummaryResponse>> getSummary(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        DashboardSummaryResponse response = from == null && to == null
                ? dashboardService.getAdminSummary()
                : dashboardService.getAdminSummary(from, to);
        return ResponseEntity.ok(ApiResponse.success("Dashboard summary", response));
    }

    @Operation(summary = "Get report statistics grouped by category")
    @GetMapping("/category")
    public ResponseEntity<ApiResponse<List<CategoryStatisticResponse>>> getCategoryStatistics(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        List<CategoryStatisticResponse> response = from == null && to == null
                ? dashboardService.getCategoryStatistics()
                : dashboardService.getCategoryStatistics(from, to);
        return ResponseEntity.ok(ApiResponse.success("Category statistics", response));
    }

    @Operation(summary = "Get report statistics grouped by department")
    @GetMapping("/department")
    public ResponseEntity<ApiResponse<List<DepartmentStatisticResponse>>> getDepartmentStatistics(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        List<DepartmentStatisticResponse> response = from == null && to == null
                ? dashboardService.getDepartmentStatistics()
                : dashboardService.getDepartmentStatistics(from, to);
        return ResponseEntity.ok(ApiResponse.success("Department statistics", response));
    }

    @Operation(summary = "Get monthly report statistics for a year")
    @GetMapping("/monthly")
    public ResponseEntity<ApiResponse<List<MonthlyStatisticResponse>>> getMonthlyStatistics(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime to) {
        int selectedYear = year == null ? Year.now().getValue() : year;
        List<MonthlyStatisticResponse> response = from == null && to == null
                ? dashboardService.getMonthlyStatistics(selectedYear)
                : dashboardService.getMonthlyStatistics(selectedYear, from, to);
        return ResponseEntity.ok(ApiResponse.success("Monthly statistics", response));
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
