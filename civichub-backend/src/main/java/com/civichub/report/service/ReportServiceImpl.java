package com.civichub.report.service;

import com.civichub.category.entity.Category;
import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.Priority;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.notification.service.NotificationService;
import com.civichub.report.dto.request.ReportCreateRequest;
import com.civichub.report.dto.request.ReportDepartmentAssignRequest;
import com.civichub.report.dto.request.ReportStatusUpdateRequest;
import com.civichub.report.dto.request.ReportUpdateRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.entity.Report;
import com.civichub.report.entity.ReportImage;
import com.civichub.report.mapper.ReportMapper;
import com.civichub.report.repository.ReportRepository;
import com.civichub.report.specification.ReportSpecification;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
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
public class ReportServiceImpl implements ReportService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("createdAt", "updatedAt", "title", "status");
    private static final Map<ReportStatus, Set<ReportStatus>> ALLOWED_STAFF_TRANSITIONS =
            new EnumMap<>(ReportStatus.class);

    static {
        ALLOWED_STAFF_TRANSITIONS.put(ReportStatus.PENDING, Set.of(ReportStatus.RECEIVED, ReportStatus.REJECTED));
        ALLOWED_STAFF_TRANSITIONS.put(ReportStatus.RECEIVED, Set.of(ReportStatus.IN_PROGRESS, ReportStatus.REJECTED));
        ALLOWED_STAFF_TRANSITIONS.put(ReportStatus.IN_PROGRESS, Set.of(ReportStatus.RESOLVED, ReportStatus.REJECTED));
    }

    private final ReportRepository reportRepository;
    private final UserRepository userRepository;
    private final CategoryRepository categoryRepository;
    private final DepartmentRepository departmentRepository;
    private final ReportMapper reportMapper;
    private final NotificationService notificationService;

    @Override
    @Transactional
    public ReportDetailResponse createReport(ReportCreateRequest request) {
        User user = getActiveCurrentUser();
        Category category = getActiveCategory(request.getCategoryId());

        Report report = Report.builder()
                .title(normalizeRequired(request.getTitle(), "Title is required"))
                .description(normalizeRequired(request.getDescription(), "Description is required"))
                .address(normalizeRequired(request.getAddress(), "Address is required"))
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .category(category)
                .user(user)
                .department(null)
                .status(ReportStatus.PENDING)
                .priority(Priority.MEDIUM)
                .build();
        replaceImages(report, request.getImageUrls());

        return reportMapper.toDetailResponse(reportRepository.save(report));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportSummaryResponse> getMyReports(
            int page,
            int size,
            String search,
            ReportStatus status,
            Long categoryId,
            String sortBy,
            String direction) {
        Long userId = currentPrincipal().getUserId();
        Page<Report> reports = reportRepository.findAll(
                ReportSpecification.filter(userId, null, status, categoryId, null, search, null, null, null),
                pageable(page, size, sortBy, direction));
        return toPageResponse(reports.map(reportMapper::toSummaryResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getMyReport(Long id) {
        return reportMapper.toDetailResponse(getOwnedReport(id));
    }

    @Override
    @Transactional
    public ReportDetailResponse updateMyReport(Long id, ReportUpdateRequest request) {
        Report report = getOwnedReport(id);
        ensurePending(report, "Only pending reports can be updated");
        Category category = getActiveCategory(request.getCategoryId());

        report.setTitle(normalizeRequired(request.getTitle(), "Title is required"));
        report.setDescription(normalizeRequired(request.getDescription(), "Description is required"));
        report.setAddress(normalizeRequired(request.getAddress(), "Address is required"));
        report.setLatitude(request.getLatitude());
        report.setLongitude(request.getLongitude());
        report.setCategory(category);
        replaceImages(report, request.getImageUrls());

        return reportMapper.toDetailResponse(reportRepository.save(report));
    }

    @Override
    @Transactional
    public ReportDetailResponse cancelMyReport(Long id) {
        Report report = getOwnedReport(id);
        ensurePending(report, "Only pending reports can be cancelled");
        report.setStatus(ReportStatus.CANCELLED);
        return reportMapper.toDetailResponse(reportRepository.save(report));
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportSummaryResponse> getStaffReports(
            int page,
            int size,
            String search,
            ReportStatus status,
            Long categoryId,
            Long citizenId,
            LocalDateTime createdFrom,
            LocalDateTime createdTo) {
        validateDateRange(createdFrom, createdTo);
        Long departmentId = getCurrentStaffDepartmentId();
        Page<Report> reports = reportRepository.findAll(
                ReportSpecification.filter(null, departmentId, status, categoryId, citizenId, search,
                        createdFrom, createdTo, null),
                pageable(page, size, null, null));
        return toPageResponse(reports.map(reportMapper::toSummaryResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getStaffReport(Long id) {
        Long departmentId = getCurrentStaffDepartmentId();
        Report report = reportRepository.findDetailByIdAndDepartmentId(id, departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Report not found"));
        return reportMapper.toDetailResponse(report);
    }

    @Override
    @Transactional
    public ReportDetailResponse updateStaffReportStatus(Long id, ReportStatusUpdateRequest request) {
        Long departmentId = getCurrentStaffDepartmentId();
        Report report = reportRepository.findDetailByIdAndDepartmentId(id, departmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Report not found"));
        ReportStatus nextStatus = request.getStatus();
        ReportStatus oldStatus = report.getStatus();
        validateTransition(report.getStatus(), nextStatus);
        report.setStatus(nextStatus);
        if (ReportStatus.RESOLVED.equals(nextStatus)) {
            report.setResolvedAt(LocalDateTime.now());
        }
        Report savedReport = reportRepository.save(report);
        notificationService.createReportStatusChangedNotification(savedReport, oldStatus, nextStatus);
        return reportMapper.toDetailResponse(savedReport);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ReportSummaryResponse> getAdminReports(
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
            String direction) {
        validateDateRange(createdFrom, createdTo);
        Page<Report> reports = reportRepository.findAll(
                ReportSpecification.filter(null, departmentId, status, categoryId, citizenId, search,
                        createdFrom, createdTo, assigned),
                pageable(page, size, sortBy, direction));
        return toPageResponse(reports.map(reportMapper::toSummaryResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getAdminReport(Long id) {
        return reportMapper.toDetailResponse(findReportDetail(id));
    }

    @Override
    @Transactional
    public ReportDetailResponse assignDepartment(Long id, ReportDepartmentAssignRequest request) {
        Report report = findReportDetail(id);
        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found"));
        if (!department.isActive()) {
            throw new InvalidReportStateException("Department is inactive");
        }
        Long currentDepartmentId = report.getDepartment() == null ? null : report.getDepartment().getId();
        if (department.getId().equals(currentDepartmentId)) {
            return reportMapper.toDetailResponse(report);
        }
        report.setDepartment(department);
        Report savedReport = reportRepository.save(report);
        notificationService.createReportAssignedNotifications(savedReport, department);
        return reportMapper.toDetailResponse(savedReport);
    }

    private Report getOwnedReport(Long id) {
        Long userId = currentPrincipal().getUserId();
        return reportRepository.findDetailByIdAndUserId(id, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Report not found"));
    }

    private Report findReportDetail(Long id) {
        return reportRepository.findDetailById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Report not found"));
    }

    private User getActiveCurrentUser() {
        User user = userRepository.findById(currentPrincipal().getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Current user not found"));
        if (!user.isActive() || !UserStatus.ACTIVE.equals(user.getStatus())) {
            throw new InvalidReportStateException("Current user is inactive");
        }
        return user;
    }

    private Category getActiveCategory(Long categoryId) {
        Category category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
        if (!category.isActive()) {
            throw new InvalidReportStateException("Category is inactive");
        }
        return category;
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

    private void validateDateRange(LocalDateTime createdFrom, LocalDateTime createdTo) {
        if (createdFrom != null && createdTo != null && createdFrom.isAfter(createdTo)) {
            throw new IllegalArgumentException("Invalid date range");
        }
    }

    private CivicHubUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CivicHubUserPrincipal principal)) {
            throw new ResourceNotFoundException("Current user not found");
        }
        return principal;
    }

    private void ensurePending(Report report, String message) {
        if (!ReportStatus.PENDING.equals(report.getStatus())) {
            throw new InvalidReportStateException(message);
        }
    }

    private void validateTransition(ReportStatus currentStatus, ReportStatus nextStatus) {
        if (currentStatus.equals(nextStatus)) {
            throw new InvalidReportStateException("Report status is unchanged");
        }
        Set<ReportStatus> allowed = ALLOWED_STAFF_TRANSITIONS.getOrDefault(currentStatus, Set.of());
        if (!allowed.contains(nextStatus)) {
            throw new InvalidReportStateException("Invalid report status transition");
        }
    }

    private void replaceImages(Report report, java.util.List<String> imageUrls) {
        report.clearImages();
        if (imageUrls == null || imageUrls.isEmpty()) {
            return;
        }

        LinkedHashSet<String> normalizedUrls = new LinkedHashSet<>();
        for (String imageUrl : imageUrls) {
            String normalized = normalizeRequired(imageUrl, "Image URL is required");
            if (!normalizedUrls.add(normalized)) {
                throw new InvalidReportStateException("Duplicate image URL is not allowed");
            }
        }

        int displayOrder = 0;
        for (String imageUrl : normalizedUrls) {
            report.addImage(ReportImage.builder()
                    .imageUrl(imageUrl)
                    .displayOrder(displayOrder++)
                    .build());
        }
    }

    private Pageable pageable(int page, int size, String sortBy, String direction) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
        String safeSortBy = ALLOWED_SORT_FIELDS.contains(sortBy) ? sortBy : "createdAt";
        Sort.Direction safeDirection = "ASC".equalsIgnoreCase(direction) ? Sort.Direction.ASC : Sort.Direction.DESC;
        return PageRequest.of(normalizedPage, normalizedSize, Sort.by(safeDirection, safeSortBy));
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

    private String normalizeRequired(String value, String message) {
        String normalized = value == null ? "" : value.trim();
        if (normalized.isBlank()) {
            throw new IllegalArgumentException(message);
        }
        return normalized;
    }
}
