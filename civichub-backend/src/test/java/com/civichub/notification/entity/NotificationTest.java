package com.civichub.notification.entity;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class NotificationTest {

    @Test
    void prePersistShouldMirrorMessageToContent() {
        Notification notification = Notification.builder()
                .title("Report assigned")
                .message("Report assigned message")
                .build();

        notification.mirrorMessageToContent();

        assertThat(notification.getTitle()).isNotBlank();
        assertThat(notification.getMessage()).isEqualTo("Report assigned message");
        assertThat(notification.getContent()).isEqualTo("Report assigned message");
    }

    @Test
    void prePersistShouldPreserveExplicitMatchingContent() {
        Notification notification = Notification.builder()
                .title("Report status updated")
                .message("Status changed")
                .content("Status changed")
                .build();

        notification.mirrorMessageToContent();

        assertThat(notification.getMessage()).isEqualTo("Status changed");
        assertThat(notification.getContent()).isEqualTo("Status changed");
    }
}
