package com.civichub.notification.service;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.NotificationType;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.notification.dto.response.NotificationReadAllResponse;
import com.civichub.notification.dto.response.NotificationResponse;
import com.civichub.notification.dto.response.UnreadNotificationCountResponse;
import com.civichub.notification.entity.Notification;
import com.civichub.notification.mapper.NotificationMapper;
import com.civichub.notification.repository.NotificationRepository;
import com.civichub.notification.specification.NotificationSpecification;
import com.civichub.report.entity.Report;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
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
public class NotificationServiceImpl implements NotificationService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> ALLOWED_SORT_FIELDS = Set.of("createdAt", "readAt", "read");

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final NotificationMapper notificationMapper;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<NotificationResponse> getMyNotifications(
            int page,
            int size,
            Boolean unread,
            NotificationType type,
            String sortBy,
            String direction) {
        Long userId = currentPrincipal().getUserId();
        Page<Notification> notifications = notificationRepository.findAll(
                NotificationSpecification.filter(userId, unread, type),
                pageable(page, size, sortBy, direction));
        return toPageResponse(notifications.map(notificationMapper::toResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public NotificationResponse getMyNotification(Long id) {
        return notificationMapper.toResponse(getOwnedNotification(id));
    }

    @Override
    @Transactional(readOnly = true)
    public UnreadNotificationCountResponse getUnreadCount() {
        return UnreadNotificationCountResponse.builder()
                .count(notificationRepository.countByUserIdAndReadFalse(currentPrincipal().getUserId()))
                .build();
    }

    @Override
    @Transactional
    public NotificationResponse markAsRead(Long id) {
        Notification notification = getOwnedNotification(id);
        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(LocalDateTime.now());
            notification = notificationRepository.save(notification);
        }
        return notificationMapper.toResponse(notification);
    }

    @Override
    @Transactional
    public NotificationReadAllResponse markAllAsRead() {
        int updatedCount = notificationRepository.markAllAsRead(currentPrincipal().getUserId(), LocalDateTime.now());
        return NotificationReadAllResponse.builder()
                .updatedCount(updatedCount)
                .build();
    }

    @Override
    @Transactional
    public void createReportAssignedNotifications(Report report, Department department) {
        List<Notification> notifications = new ArrayList<>();
        notifications.add(Notification.builder()
                .user(report.getUser())
                .report(report)
                .type(NotificationType.REPORT_ASSIGNED)
                .title("Report assigned")
                .message("Your report \"%s\" has been assigned to \"%s\"."
                        .formatted(report.getTitle(), department.getName()))
                .build());

        List<User> staffRecipients = userRepository.findByRoleAndStatusAndIsActiveTrueAndDepartmentId(
                UserRole.STAFF,
                UserStatus.ACTIVE,
                department.getId());
        staffRecipients.forEach(staff -> notifications.add(Notification.builder()
                .user(staff)
                .report(report)
                .type(NotificationType.REPORT_ASSIGNED)
                .title("New report assigned")
                .message("A report \"%s\" has been assigned to your department."
                        .formatted(report.getTitle()))
                .build()));

        notificationRepository.saveAll(notifications);
    }

    @Override
    @Transactional
    public void createReportStatusChangedNotification(Report report, ReportStatus oldStatus, ReportStatus newStatus) {
        notificationRepository.save(Notification.builder()
                .user(report.getUser())
                .report(report)
                .type(NotificationType.REPORT_STATUS_CHANGED)
                .title("Report status updated")
                .message("Your report \"%s\" changed from \"%s\" to \"%s\"."
                        .formatted(report.getTitle(), oldStatus.name(), newStatus.name()))
                .build());
    }

    private Notification getOwnedNotification(Long id) {
        return notificationRepository.findByIdAndUserId(id, currentPrincipal().getUserId())
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));
    }

    private CivicHubUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CivicHubUserPrincipal principal)) {
            throw new ResourceNotFoundException("Current user not found");
        }
        return principal;
    }

    private Pageable pageable(int page, int size, String sortBy, String direction) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
        String safeSortBy = ALLOWED_SORT_FIELDS.contains(sortBy) ? sortBy : "createdAt";
        Sort.Direction safeDirection = "ASC".equalsIgnoreCase(direction) ? Sort.Direction.ASC : Sort.Direction.DESC;
        return PageRequest.of(normalizedPage, normalizedSize, Sort.by(safeDirection, safeSortBy));
    }

    private PageResponse<NotificationResponse> toPageResponse(Page<NotificationResponse> page) {
        return PageResponse.<NotificationResponse>builder()
                .content(page.getContent())
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .first(page.isFirst())
                .last(page.isLast())
                .build();
    }
}
