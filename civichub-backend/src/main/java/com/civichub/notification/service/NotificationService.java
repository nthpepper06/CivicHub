package com.civichub.notification.service;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.NotificationType;
import com.civichub.common.enums.ReportStatus;
import com.civichub.department.entity.Department;
import com.civichub.notification.dto.response.NotificationReadAllResponse;
import com.civichub.notification.dto.response.NotificationResponse;
import com.civichub.notification.dto.response.UnreadNotificationCountResponse;
import com.civichub.report.entity.Report;

public interface NotificationService {

    PageResponse<NotificationResponse> getMyNotifications(
            int page,
            int size,
            Boolean unread,
            NotificationType type,
            String sortBy,
            String direction);

    NotificationResponse getMyNotification(Long id);

    UnreadNotificationCountResponse getUnreadCount();

    NotificationResponse markAsRead(Long id);

    NotificationReadAllResponse markAllAsRead();

    void createReportAssignedNotifications(Report report, Department department);

    void createReportStatusChangedNotification(Report report, ReportStatus oldStatus, ReportStatus newStatus);
}
