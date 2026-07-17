package com.civichub.notification.dto.response;

import com.civichub.common.enums.NotificationType;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponse {

    private Long id;
    private NotificationType type;
    private String title;
    private String message;
    private Long reportId;
    private boolean read;
    private LocalDateTime readAt;
    private LocalDateTime createdAt;
}
