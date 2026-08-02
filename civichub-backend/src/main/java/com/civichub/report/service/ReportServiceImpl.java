package com.civichub.report.service;

import com.civichub.audit.service.AuditService;
import com.civichub.category.entity.Category;
import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.PageResponse;
import com.civichub.common.CsvUtils;
import com.civichub.common.enums.Priority;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.ReportTimelineEventType;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.notification.service.NotificationService;
import com.civichub.report.dto.request.ReportCreateRequest;
import com.civichub.report.dto.request.ReportDepartmentAssignRequest;
import com.civichub.report.dto.request.ReportRatingRequest;
import com.civichub.report.dto.request.ReportStatusUpdateRequest;
import com.civichub.report.dto.request.ReportUpdateRequest;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportImageResponse;
import com.civichub.report.dto.response.ReportRatingResponse;
import com.civichub.report.dto.response.ReportResolutionResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.dto.response.ReportTimelineEventResponse;
import com.civichub.report.entity.Report;
import com.civichub.report.entity.ReportImage;
import com.civichub.report.entity.ReportRating;
import com.civichub.report.entity.ReportResolution;
import com.civichub.report.entity.ReportResolutionImage;
import com.civichub.report.entity.ReportTimelineEvent;
import com.civichub.report.mapper.ReportMapper;
import com.civichub.report.repository.ReportRatingRepository;
import com.civichub.report.repository.ReportRepository;
import com.civichub.report.repository.ReportResolutionRepository;
import com.civichub.report.repository.ReportTimelineEventRepository;
import com.civichub.report.specification.ReportSpecification;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.EnumMap;
import java.util.LinkedHashSet;
import java.util.Comparator;
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
    private static final int MAX_EXPORT_SIZE = 5000;
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
    private final AuditService auditService;
    private final ReportTimelineEventRepository timelineEventRepository;
    private final ReportResolutionRepository resolutionRepository;
    private final ReportRatingRepository ratingRepository;

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

        Report savedReport = reportRepository.save(report);
        recordTimelineEvent(
                savedReport,
                ReportTimelineEventType.REPORT_CREATED,
                "Report created",
                "Citizen created the report.",
                user);
        return toDetailResponse(savedReport);
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
        return toDetailResponse(getOwnedReport(id));
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

        return toDetailResponse(reportRepository.save(report));
    }

    @Override
    @Transactional
    public ReportDetailResponse cancelMyReport(Long id) {
        Report report = getOwnedReport(id);
        ensurePending(report, "Only pending reports can be cancelled");
        report.setStatus(ReportStatus.CANCELLED);
        Report savedReport = reportRepository.save(report);
        auditService.recordReportCancelled(savedReport.getId(), savedReport.getTitle());
        recordTimelineEvent(
                savedReport,
                ReportTimelineEventType.CANCELLED,
                "Report cancelled",
                "Citizen cancelled the pending report.",
                report.getUser());
        return toDetailResponse(savedReport);
    }

    @Override
    @Transactional
    public ReportDetailResponse confirmMyReportResolution(Long id) {
        Report report = getOwnedReport(id);
        if (!ReportStatus.RESOLVED.equals(report.getStatus())) {
            throw new InvalidReportStateException("Only resolved reports can be confirmed");
        }
        ReportResolution resolution = resolutionRepository.findByReportId(report.getId())
                .orElseThrow(() -> new InvalidReportStateException("Resolution details are not available"));
        if (resolution.getCitizenConfirmedAt() == null) {
            resolution.setCitizenConfirmedAt(LocalDateTime.now());
            resolutionRepository.save(resolution);
            recordTimelineEvent(
                    report,
                    ReportTimelineEventType.CITIZEN_CONFIRMED,
                    "Citizen confirmed resolution",
                    "Citizen confirmed the report resolution.",
                    report.getUser());
        }
        return toDetailResponse(report);
    }

    @Override
    @Transactional
    public ReportDetailResponse rateMyReportResolution(Long id, ReportRatingRequest request) {
        Report report = getOwnedReport(id);
        if (!ReportStatus.RESOLVED.equals(report.getStatus())) {
            throw new InvalidReportStateException("Only resolved reports can be rated");
        }
        User user = report.getUser();
        ReportRating rating = ratingRepository.findByReportId(report.getId())
                .orElseGet(() -> ReportRating.builder()
                        .report(report)
                        .user(user)
                        .build());
        rating.setRating(request.getRating());
        rating.setComment(normalizeOptional(request.getComment()));
        ratingRepository.save(rating);
        recordTimelineEvent(
                report,
                ReportTimelineEventType.RATING_SUBMITTED,
                "Rating submitted",
                "Citizen rated the completed resolution.",
                user);
        return toDetailResponse(report);
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
        return toDetailResponse(report);
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
            upsertResolution(report, request);
        }
        Report savedReport = reportRepository.save(report);
        notificationService.createReportStatusChangedNotification(savedReport, oldStatus, nextStatus);
        auditService.recordReportStatusChanged(savedReport.getId(), savedReport.getTitle(), oldStatus, nextStatus);
        recordStatusTimelineEvent(savedReport, oldStatus, nextStatus);
        return toDetailResponse(savedReport);
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
    public String exportAdminReportsCsv(
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
                pageable(0, MAX_EXPORT_SIZE, sortBy, direction));
        StringBuilder csv = new StringBuilder('\ufeff' + CsvUtils.row(
                CsvUtils.trusted("ID"),
                CsvUtils.trusted("Title"),
                CsvUtils.trusted("Address"),
                CsvUtils.trusted("Status"),
                CsvUtils.trusted("Category"),
                CsvUtils.trusted("Department"),
                CsvUtils.trusted("Citizen"),
                CsvUtils.trusted("Priority"),
                CsvUtils.trusted("Created At"),
                CsvUtils.trusted("Updated At")));
        reports.getContent()
                .forEach(report -> csv.append('\n').append(CsvUtils.row(
                        CsvUtils.trusted(report.getId()),
                        CsvUtils.text(report.getTitle()),
                        CsvUtils.text(report.getAddress()),
                        CsvUtils.trusted(report.getStatus()),
                        CsvUtils.text(report.getCategory().getName()),
                        CsvUtils.text(report.getDepartment() == null ? null : report.getDepartment().getName()),
                        CsvUtils.text(report.getUser().getFullName()),
                        CsvUtils.trusted(report.getPriority()),
                        CsvUtils.trusted(report.getCreatedAt()),
                        CsvUtils.trusted(report.getUpdatedAt()))));
        return csv.toString();
    }

    @Override
    @Transactional(readOnly = true)
    public ReportDetailResponse getAdminReport(Long id) {
        return toDetailResponse(findReportDetail(id));
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
        Department oldDepartment = report.getDepartment();
        Long currentDepartmentId = oldDepartment == null ? null : oldDepartment.getId();
        if (department.getId().equals(currentDepartmentId)) {
            return toDetailResponse(report);
        }
        report.setDepartment(department);
        Report savedReport = reportRepository.save(report);
        notificationService.createReportAssignedNotifications(savedReport, department);
        auditService.recordReportAssignment(savedReport.getId(), savedReport.getTitle(), oldDepartment, department);
        recordTimelineEvent(
                savedReport,
                ReportTimelineEventType.DEPARTMENT_ASSIGNED,
                oldDepartment == null ? "Department assigned" : "Department reassigned",
                "Report assigned to %s.".formatted(department.getName()),
                currentUserOrNull());
        return toDetailResponse(savedReport);
    }

    @Override
    @Transactional
    public ReportDetailResponse updateAdminReportStatus(Long id, ReportStatusUpdateRequest request) {
        Report report = findReportDetail(id);
        ReportStatus nextStatus = request.getStatus();
        ReportStatus oldStatus = report.getStatus();
        validateTransition(oldStatus, nextStatus);
        report.setStatus(nextStatus);
        report.setResolvedAt(ReportStatus.RESOLVED.equals(nextStatus) ? LocalDateTime.now() : null);
        if (ReportStatus.RESOLVED.equals(nextStatus)) {
            upsertResolution(report, request);
        }
        Report savedReport = reportRepository.save(report);
        notificationService.createReportStatusChangedNotification(savedReport, oldStatus, nextStatus);
        auditService.recordReportStatusChanged(savedReport.getId(), savedReport.getTitle(), oldStatus, nextStatus);
        recordStatusTimelineEvent(savedReport, oldStatus, nextStatus);
        return toDetailResponse(savedReport);
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

    private void upsertResolution(Report report, ReportStatusUpdateRequest request) {
        String summary = normalizeRequired(
                request.getResolutionSummary(),
                "Resolution summary is required when resolving a report");
        ReportResolution resolution = resolutionRepository.findByReportId(report.getId())
                .orElseGet(() -> ReportResolution.builder()
                        .report(report)
                        .resolvedBy(currentUserOrNull())
                        .build());
        resolution.setSummary(summary);
        resolution.setWorkPerformed(normalizeOptional(request.getWorkPerformed()));
        resolution.setPublicNote(normalizeOptional(request.getPublicNote()));
        resolution.setResolvedBy(currentUserOrNull());
        replaceResolutionImages(resolution, request.getResolutionImageUrls());
        resolutionRepository.save(resolution);

        recordTimelineEvent(
                report,
                ReportTimelineEventType.STAFF_NOTE_ADDED,
                "Resolution note added",
                "Staff added resolution details.",
                resolution.getResolvedBy());
        if (request.getResolutionImageUrls() != null && !request.getResolutionImageUrls().isEmpty()) {
            recordTimelineEvent(
                    report,
                    ReportTimelineEventType.RESOLUTION_IMAGES_UPLOADED,
                    "Resolution photos uploaded",
                    "Staff attached resolution evidence photos.",
                    resolution.getResolvedBy());
        }
    }

    private void replaceResolutionImages(ReportResolution resolution, java.util.List<String> imageUrls) {
        resolution.clearImages();
        if (imageUrls == null || imageUrls.isEmpty()) {
            return;
        }
        LinkedHashSet<String> normalizedUrls = new LinkedHashSet<>();
        for (String imageUrl : imageUrls) {
            String normalized = normalizeRequired(imageUrl, "Resolution image URL is required");
            if (!normalizedUrls.add(normalized)) {
                throw new InvalidReportStateException("Duplicate resolution image URL is not allowed");
            }
        }

        int displayOrder = 0;
        for (String imageUrl : normalizedUrls) {
            resolution.addImage(ReportResolutionImage.builder()
                    .imageUrl(imageUrl)
                    .displayOrder(displayOrder++)
                    .build());
        }
    }

    private void recordStatusTimelineEvent(Report report, ReportStatus oldStatus, ReportStatus nextStatus) {
        ReportTimelineEventType eventType = switch (nextStatus) {
            case RECEIVED -> ReportTimelineEventType.STAFF_ACCEPTED;
            case IN_PROGRESS -> ReportTimelineEventType.STATUS_IN_PROGRESS;
            case RESOLVED -> ReportTimelineEventType.RESOLVED;
            case REJECTED -> ReportTimelineEventType.REJECTED;
            case CANCELLED -> ReportTimelineEventType.CANCELLED;
            case PENDING -> ReportTimelineEventType.REPORT_CREATED;
        };
        recordTimelineEvent(
                report,
                eventType,
                "Status changed to %s".formatted(nextStatus.name()),
                "Report changed from %s to %s.".formatted(oldStatus.name(), nextStatus.name()),
                currentUserOrNull());
    }

    private void recordTimelineEvent(
            Report report,
            ReportTimelineEventType eventType,
            String title,
            String description,
            User actor) {
        timelineEventRepository.save(ReportTimelineEvent.builder()
                .report(report)
                .eventType(eventType)
                .title(title)
                .description(description)
                .actor(actor)
                .actorRole(actor == null ? null : actor.getRole())
                .actorName(actor == null ? null : actor.getFullName())
                .build());
    }

    private ReportDetailResponse toDetailResponse(Report report) {
        ReportDetailResponse response = reportMapper.toDetailResponse(report);
        response.setTimeline(timelineEventRepository.findByReportIdOrderByCreatedAtAscIdAsc(report.getId())
                .stream()
                .map(this::toTimelineResponse)
                .toList());
        response.setResolution(resolutionRepository.findByReportId(report.getId())
                .map(this::toResolutionResponse)
                .orElse(null));
        response.setRating(ratingRepository.findByReportId(report.getId())
                .map(this::toRatingResponse)
                .orElse(null));
        return response;
    }

    private ReportTimelineEventResponse toTimelineResponse(ReportTimelineEvent event) {
        return ReportTimelineEventResponse.builder()
                .id(event.getId())
                .type(event.getEventType())
                .title(event.getTitle())
                .description(event.getDescription())
                .actorRole(event.getActorRole())
                .actorName(event.getActorName())
                .createdAt(event.getCreatedAt())
                .build();
    }

    private ReportResolutionResponse toResolutionResponse(ReportResolution resolution) {
        return ReportResolutionResponse.builder()
                .id(resolution.getId())
                .summary(resolution.getSummary())
                .workPerformed(resolution.getWorkPerformed())
                .publicNote(resolution.getPublicNote())
                .resolvedByName(resolution.getResolvedBy() == null ? null : resolution.getResolvedBy().getFullName())
                .resolvedAt(resolution.getCreatedAt())
                .citizenConfirmedAt(resolution.getCitizenConfirmedAt())
                .images(resolution.getImages()
                        .stream()
                        .sorted(Comparator.comparingInt(ReportResolutionImage::getDisplayOrder))
                        .map(image -> ReportImageResponse.builder()
                                .id(image.getId())
                                .url(image.getImageUrl())
                                .displayOrder(image.getDisplayOrder())
                                .build())
                        .toList())
                .build();
    }

    private ReportRatingResponse toRatingResponse(ReportRating rating) {
        return ReportRatingResponse.builder()
                .id(rating.getId())
                .rating(rating.getRating())
                .comment(rating.getComment())
                .createdAt(rating.getCreatedAt())
                .updatedAt(rating.getUpdatedAt())
                .build();
    }

    private User currentUserOrNull() {
        try {
            return userRepository.findById(currentPrincipal().getUserId()).orElse(null);
        } catch (RuntimeException ignored) {
            return null;
        }
    }

    private Pageable pageable(int page, int size, String sortBy, String direction) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
        String safeSortBy = sortBy == null || !ALLOWED_SORT_FIELDS.contains(sortBy) ? "createdAt" : sortBy;
        String safeDirectionValue = direction == null ? "DESC" : direction;
        Sort.Direction safeDirection = "ASC".equalsIgnoreCase(safeDirectionValue) ? Sort.Direction.ASC : Sort.Direction.DESC;
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

    private String normalizeOptional(String value) {
        String normalized = value == null ? "" : value.trim();
        return normalized.isBlank() ? null : normalized;
    }
}
