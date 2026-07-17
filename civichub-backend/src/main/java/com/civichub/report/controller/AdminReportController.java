package com.civichub.report.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.report.dto.request.ReportDepartmentAssignRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import java.time.LocalDateTime;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "bearerAuth")
public class AdminReportController {

    private final ReportService reportService;

    @Operation(summary = "List all reports with filters")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ReportSummaryResponse>>> getAdminReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) Long citizenId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo,
            @RequestParam(required = false) Boolean assigned,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(ApiResponse.success(
                "Reports",
                reportService.getAdminReports(page, size, search, status, categoryId, departmentId, citizenId,
                        createdFrom, createdTo, assigned, sortBy, direction)));
    }

    @Operation(summary = "Get admin report detail")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> getAdminReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Report", reportService.getAdminReport(id)));
    }

    @Operation(summary = "Assign report to an active department")
    @PatchMapping("/{id}/department")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> assignDepartment(
            @PathVariable Long id,
            @Valid @RequestBody ReportDepartmentAssignRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Report department assigned",
                reportService.assignDepartment(id, request)));
    }
}
