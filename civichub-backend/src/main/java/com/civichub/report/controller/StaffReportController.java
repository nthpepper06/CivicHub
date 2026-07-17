package com.civichub.report.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.report.dto.request.ReportStatusUpdateRequest;
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
@RequestMapping("/api/staff/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('STAFF')")
@SecurityRequirement(name = "bearerAuth")
public class StaffReportController {

    private final ReportService reportService;

    @Operation(summary = "List reports assigned to current staff department")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ReportSummaryResponse>>> getStaffReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) Long citizenId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdFrom,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime createdTo) {
        return ResponseEntity.ok(ApiResponse.success(
                "Staff reports",
                reportService.getStaffReports(page, size, search, status, categoryId, citizenId, createdFrom, createdTo)));
    }

    @Operation(summary = "Get staff department report detail")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> getStaffReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Report", reportService.getStaffReport(id)));
    }

    @Operation(summary = "Update staff report processing status")
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> updateReportStatus(
            @PathVariable Long id,
            @Valid @RequestBody ReportStatusUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Report status updated",
                reportService.updateStaffReportStatus(id, request)));
    }
}
