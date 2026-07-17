package com.civichub.report.service;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.ReportStatus;
import com.civichub.report.dto.request.ReportCreateRequest;
import com.civichub.report.dto.request.ReportDepartmentAssignRequest;
import com.civichub.report.dto.request.ReportStatusUpdateRequest;
import com.civichub.report.dto.request.ReportUpdateRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import java.time.LocalDateTime;

public interface ReportService {

    ReportDetailResponse createReport(ReportCreateRequest request);

    PageResponse<ReportSummaryResponse> getMyReports(
            int page,
            int size,
            String search,
            ReportStatus status,
            Long categoryId,
            String sortBy,
            String direction);

    ReportDetailResponse getMyReport(Long id);

    ReportDetailResponse updateMyReport(Long id, ReportUpdateRequest request);

    ReportDetailResponse cancelMyReport(Long id);

    PageResponse<ReportSummaryResponse> getStaffReports(
            int page,
            int size,
            String search,
            ReportStatus status,
            Long categoryId,
            Long citizenId,
            LocalDateTime createdFrom,
            LocalDateTime createdTo);

    ReportDetailResponse getStaffReport(Long id);

    ReportDetailResponse updateStaffReportStatus(Long id, ReportStatusUpdateRequest request);

    PageResponse<ReportSummaryResponse> getAdminReports(
            int page,
            int size,
            String search,
            ReportStatus status,
            Long categoryId,
            Long departmentId,
            Long citizenId,
            LocalDateTime createdFrom,
            LocalDateTime createdTo,
            Boolean assigned,
            String sortBy,
            String direction);

    ReportDetailResponse getAdminReport(Long id);

    ReportDetailResponse assignDepartment(Long id, ReportDepartmentAssignRequest request);
}
