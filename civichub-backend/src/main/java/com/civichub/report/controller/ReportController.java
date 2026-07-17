package com.civichub.report.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.report.dto.request.ReportCreateRequest;
import com.civichub.report.dto.request.ReportUpdateRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('CITIZEN')")
@SecurityRequirement(name = "bearerAuth")
public class ReportController {

    private final ReportService reportService;

    @Operation(summary = "Create a citizen report")
    @PostMapping
    public ResponseEntity<ApiResponse<ReportDetailResponse>> createReport(
            @Valid @RequestBody ReportCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Report created", reportService.createReport(request)));
    }

    @Operation(summary = "List current citizen reports")
    @GetMapping("/my")
    public ResponseEntity<ApiResponse<PageResponse<ReportSummaryResponse>>> getMyReports(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) ReportStatus status,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(ApiResponse.success(
                "My reports",
                reportService.getMyReports(page, size, search, status, categoryId, sortBy, direction)));
    }

    @Operation(summary = "Get current citizen report detail")
    @GetMapping("/my/{id}")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> getMyReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Report", reportService.getMyReport(id)));
    }

    @Operation(summary = "Update current citizen pending report")
    @PutMapping("/my/{id}")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> updateMyReport(
            @PathVariable Long id,
            @Valid @RequestBody ReportUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Report updated", reportService.updateMyReport(id, request)));
    }

    @Operation(summary = "Cancel current citizen pending report")
    @PatchMapping("/my/{id}/cancel")
    public ResponseEntity<ApiResponse<ReportDetailResponse>> cancelMyReport(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Report cancelled", reportService.cancelMyReport(id)));
    }
}
