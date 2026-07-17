package com.civichub.notification.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.NotificationType;
import com.civichub.notification.dto.response.NotificationReadAllResponse;
import com.civichub.notification.dto.response.NotificationResponse;
import com.civichub.notification.dto.response.UnreadNotificationCountResponse;
import com.civichub.notification.service.NotificationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
@PreAuthorize("isAuthenticated()")
@SecurityRequirement(name = "bearerAuth")
public class NotificationController {

    private final NotificationService notificationService;

    @Operation(
            summary = "List current user's notifications",
            description = "Supports pagination, unread filter, type filter, and safe sorting. "
                    + "Only notifications owned by the authenticated user are returned.")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<NotificationResponse>>> getMyNotifications(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) Boolean unread,
            @RequestParam(required = false) NotificationType type,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(ApiResponse.success(
                "Notifications",
                notificationService.getMyNotifications(page, size, unread, type, sortBy, direction)));
    }

    @Operation(
            summary = "Get one notification",
            description = "Returns 404 when the notification does not belong to the authenticated user.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<NotificationResponse>> getMyNotification(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Notification", notificationService.getMyNotification(id)));
    }

    @Operation(summary = "Get unread notification count")
    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<UnreadNotificationCountResponse>> getUnreadCount() {
        return ResponseEntity.ok(ApiResponse.success("Unread notification count", notificationService.getUnreadCount()));
    }

    @Operation(
            summary = "Mark one notification as read",
            description = "Idempotent. Already-read notifications keep their original readAt value.")
    @PatchMapping("/{id}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markAsRead(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Notification marked as read", notificationService.markAsRead(id)));
    }

    @Operation(
            summary = "Mark all notifications as read",
            description = "Marks all unread notifications owned by the authenticated user using a recipient-scoped bulk update.")
    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<NotificationReadAllResponse>> markAllAsRead() {
        return ResponseEntity.ok(ApiResponse.success("Notifications marked as read", notificationService.markAllAsRead()));
    }
}
