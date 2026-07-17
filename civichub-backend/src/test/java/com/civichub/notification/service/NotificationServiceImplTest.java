package com.civichub.notification.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.category.entity.Category;
import com.civichub.common.enums.NotificationType;
import com.civichub.common.enums.Priority;
import com.civichub.common.enums.ReportStatus;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.notification.entity.Notification;
import com.civichub.notification.mapper.NotificationMapper;
import com.civichub.notification.repository.NotificationRepository;
import com.civichub.report.entity.Report;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.entity.User;
import com.civichub.user.repository.UserRepository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class NotificationServiceImplTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private UserRepository userRepository;

    private NotificationServiceImpl notificationService;

    @BeforeEach
    void setUp() {
        notificationService = new NotificationServiceImpl(
                notificationRepository,
                userRepository,
                new NotificationMapper());
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void listShouldQueryOnlyCurrentUserNotificationsWithSafePaging() {
        authenticate(1L, UserRole.CITIZEN);
        when(notificationRepository.findAll(anyNotificationSpecification(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(notification(10L, citizen(1L), false))));

        var response = notificationService.getMyNotifications(0, 150, true, NotificationType.REPORT_ASSIGNED, "bad", "ASC");

        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(notificationRepository).findAll(anyNotificationSpecification(), pageableCaptor.capture());
        assertThat(response.getContent()).hasSize(1);
        assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(100);
        assertThat(pageableCaptor.getValue().getSort().getOrderFor("createdAt").isAscending()).isTrue();
    }

    @Test
    void detailShouldUseRecipientScopedLookup() {
        authenticate(1L, UserRole.CITIZEN);
        when(notificationRepository.findByIdAndUserId(10L, 1L))
                .thenReturn(Optional.of(notification(10L, citizen(1L), false)));

        var response = notificationService.getMyNotification(10L);

        assertThat(response.getId()).isEqualTo(10L);
        verify(notificationRepository).findByIdAndUserId(10L, 1L);
    }

    @Test
    void anotherUsersNotificationShouldNotBeExposed() {
        authenticate(1L, UserRole.CITIZEN);
        when(notificationRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> notificationService.getMyNotification(10L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void markReadShouldSetReadTrueAndReadAt() {
        authenticate(1L, UserRole.CITIZEN);
        Notification notification = notification(10L, citizen(1L), false);
        when(notificationRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(notification));
        when(notificationRepository.save(notification)).thenReturn(notification);

        var response = notificationService.markAsRead(10L);

        assertThat(response.isRead()).isTrue();
        assertThat(response.getReadAt()).isNotNull();
        verify(notificationRepository).save(notification);
    }

    @Test
    void alreadyReadNotificationShouldBeIdempotentAndKeepReadAt() {
        authenticate(1L, UserRole.CITIZEN);
        LocalDateTime readAt = LocalDateTime.parse("2026-01-01T10:00:00");
        Notification notification = notification(10L, citizen(1L), true);
        notification.setReadAt(readAt);
        when(notificationRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(notification));

        var response = notificationService.markAsRead(10L);

        assertThat(response.getReadAt()).isEqualTo(readAt);
        verify(notificationRepository, never()).save(any(Notification.class));
    }

    @Test
    void unreadCountShouldUseRepositoryCount() {
        authenticate(1L, UserRole.CITIZEN);
        when(notificationRepository.countByUserIdAndReadFalse(1L)).thenReturn(5L);

        var response = notificationService.getUnreadCount();

        assertThat(response.getCount()).isEqualTo(5);
        verify(notificationRepository).countByUserIdAndReadFalse(1L);
    }

    @Test
    void markAllReadShouldUseRecipientScopedBulkUpdate() {
        authenticate(1L, UserRole.CITIZEN);
        when(notificationRepository.markAllAsRead(org.mockito.ArgumentMatchers.eq(1L), any(LocalDateTime.class)))
                .thenReturn(3);

        var response = notificationService.markAllAsRead();

        assertThat(response.getUpdatedCount()).isEqualTo(3);
    }

    @Test
    void reportAssignmentShouldNotifyCitizenAndActiveStaffInTargetDepartment() {
        User citizen = citizen(1L);
        User staff = staff(2L, department(5L));
        Department department = department(5L);
        Report report = report(citizen, department);
        when(userRepository.findByRoleAndStatusAndIsActiveTrueAndDepartmentId(
                UserRole.STAFF,
                UserStatus.ACTIVE,
                5L))
                .thenReturn(List.of(staff));

        notificationService.createReportAssignedNotifications(report, department);

        ArgumentCaptor<List<Notification>> captor = notificationListCaptor();
        verify(notificationRepository).saveAll(captor.capture());
        assertThat(captor.getValue()).hasSize(2);
        assertThat(captor.getValue()).extracting(notification -> notification.getUser().getId())
                .containsExactly(1L, 2L);
        assertThat(captor.getValue()).allSatisfy(notification -> {
            assertThat(notification.getType()).isEqualTo(NotificationType.REPORT_ASSIGNED);
            assertThat(notification.getReport()).isEqualTo(report);
        });
    }

    @Test
    void reportAssignmentShouldStillNotifyCitizenWhenDepartmentHasNoStaff() {
        User citizen = citizen(1L);
        Department department = department(5L);
        Report report = report(citizen, department);
        when(userRepository.findByRoleAndStatusAndIsActiveTrueAndDepartmentId(
                UserRole.STAFF,
                UserStatus.ACTIVE,
                5L))
                .thenReturn(List.of());

        notificationService.createReportAssignedNotifications(report, department);

        ArgumentCaptor<List<Notification>> captor = notificationListCaptor();
        verify(notificationRepository).saveAll(captor.capture());
        assertThat(captor.getValue()).hasSize(1);
        assertThat(captor.getValue().getFirst().getUser()).isEqualTo(citizen);
    }

    @Test
    void statusChangeShouldNotifyCitizenWithOldAndNewStatusSemantics() {
        User citizen = citizen(1L);
        Report report = report(citizen, department(5L));

        notificationService.createReportStatusChangedNotification(
                report,
                ReportStatus.PENDING,
                ReportStatus.RECEIVED);

        ArgumentCaptor<Notification> captor = ArgumentCaptor.forClass(Notification.class);
        verify(notificationRepository).save(captor.capture());
        assertThat(captor.getValue().getType()).isEqualTo(NotificationType.REPORT_STATUS_CHANGED);
        assertThat(captor.getValue().getUser()).isEqualTo(citizen);
        assertThat(captor.getValue().getMessage()).contains("PENDING", "RECEIVED");
    }

    private void authenticate(Long userId, UserRole role) {
        CivicHubUserPrincipal principal = new CivicHubUserPrincipal(
                userId,
                "user@example.com",
                "encoded",
                role,
                true);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }

    private Specification<Notification> anyNotificationSpecification() {
        return any();
    }

    @SuppressWarnings("unchecked")
    private ArgumentCaptor<List<Notification>> notificationListCaptor() {
        return ArgumentCaptor.forClass(List.class);
    }

    private Notification notification(Long id, User user, boolean read) {
        Notification notification = Notification.builder()
                .id(id)
                .user(user)
                .report(report(user, department(5L)))
                .type(NotificationType.REPORT_ASSIGNED)
                .title("Report assigned")
                .message("Message")
                .read(read)
                .build();
        notification.setCreatedAt(LocalDateTime.parse("2026-01-01T10:00:00"));
        return notification;
    }

    private Report report(User user, Department department) {
        return Report.builder()
                .id(99L)
                .title("Broken street light")
                .description("Description")
                .address("Address")
                .status(ReportStatus.PENDING)
                .priority(Priority.MEDIUM)
                .user(user)
                .department(department)
                .category(Category.builder().id(10L).name("Lighting").isActive(true).build())
                .build();
    }

    private User citizen(Long id) {
        return User.builder()
                .id(id)
                .fullName("Citizen")
                .email("citizen@example.com")
                .password("encoded")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }

    private User staff(Long id, Department department) {
        return User.builder()
                .id(id)
                .fullName("Staff")
                .email("staff@example.com")
                .password("encoded")
                .role(UserRole.STAFF)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .department(department)
                .build();
    }

    private Department department(Long id) {
        return Department.builder()
                .id(id)
                .name("Urban Services")
                .isActive(true)
                .build();
    }
}
