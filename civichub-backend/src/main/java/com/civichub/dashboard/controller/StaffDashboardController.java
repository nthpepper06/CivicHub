package com.civichub.dashboard.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.dashboard.service.DashboardService;
import com.civichub.report.dto.response.ReportSummaryResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/staff/dashboard")
@RequiredArgsConstructor
@PreAuthorize("hasRole('STAFF')")
@SecurityRequirement(name = "bearerAuth")
public class StaffDashboardController {

    private final DashboardService dashboardService;

    @Operation(summary = "Get staff department dashboard summary")
    @GetMapping("/summary")
    public ResponseEntity<ApiResponse<StaffDashboardSummaryResponse>> getSummary() {
        return ResponseEntity.ok(ApiResponse.success("Staff dashboard summary", dashboardService.getStaffSummary()));
    }

    @Operation(summary = "Get recent reports for staff department dashboard")
    @GetMapping("/recent")
    public ResponseEntity<ApiResponse<PageResponse<ReportSummaryResponse>>> getRecentReports(
            @RequestParam(defaultValue = "10") int size) {
        return ResponseEntity.ok(ApiResponse.success(
                "Recent staff reports",
                dashboardService.getStaffRecentReports(size)));
    }
}
