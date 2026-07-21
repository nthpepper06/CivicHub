package com.civichub.notification.controller;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.NotificationType;
import com.civichub.notification.dto.response.NotificationReadAllResponse;
import com.civichub.notification.dto.response.NotificationResponse;
import com.civichub.notification.dto.response.UnreadNotificationCountResponse;
import com.civichub.notification.service.NotificationService;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(NotificationController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class NotificationControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private NotificationService notificationService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void unauthenticatedUserReceivesUnauthorized() throws Exception {
        mockMvc.perform(get("/api/notifications"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedCitizenCanListNotifications() throws Exception {
        when(notificationService.getMyNotifications(0, 10, null, null, null, null))
                .thenReturn(PageResponse.<NotificationResponse>builder()
                        .content(List.of(NotificationResponse.builder().id(10L).build()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/notifications")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(10));
    }

    @Test
    void authenticatedStaffCanListNotifications() throws Exception {
        when(notificationService.getMyNotifications(0, 10, null, null, null, null))
                .thenReturn(PageResponse.<NotificationResponse>builder().content(List.of()).build());

        mockMvc.perform(get("/api/notifications")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isOk());
    }

    @Test
    void authenticatedAdminCanListNotifications() throws Exception {
        when(notificationService.getMyNotifications(0, 10, null, null, null, null))
                .thenReturn(PageResponse.<NotificationResponse>builder().content(List.of()).build());

        mockMvc.perform(get("/api/notifications")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk());
    }

    @Test
    void userCannotRetrieveAnotherUsersNotification() throws Exception {
        when(notificationService.getMyNotification(10L))
                .thenThrow(new com.civichub.common.exception.ResourceNotFoundException("Notification not found"));

        mockMvc.perform(get("/api/notifications/10")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isNotFound());
    }

    @Test
    void markReadReturnsOk() throws Exception {
        when(notificationService.markAsRead(10L))
                .thenReturn(NotificationResponse.builder().id(10L).read(true).build());

        mockMvc.perform(patch("/api/notifications/10/read")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.read").value(true));
    }

    @Test
    void markAllReadReturnsOk() throws Exception {
        when(notificationService.markAllAsRead())
                .thenReturn(NotificationReadAllResponse.builder().updatedCount(5).build());

        mockMvc.perform(patch("/api/notifications/read-all")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.updatedCount").value(5));
    }

    @Test
    void markSelectedReadReturnsOkAndPassesIdsToService() throws Exception {
        when(notificationService.markSelectedAsRead(org.mockito.ArgumentMatchers.any()))
                .thenReturn(NotificationReadAllResponse.builder().updatedCount(2).build());

        mockMvc.perform(patch("/api/notifications/read")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"notificationIds\":[10,11]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.updatedCount").value(2));

        ArgumentCaptor<com.civichub.notification.dto.request.NotificationBulkReadRequest> requestCaptor =
                ArgumentCaptor.forClass(com.civichub.notification.dto.request.NotificationBulkReadRequest.class);
        verify(notificationService).markSelectedAsRead(requestCaptor.capture());
        org.assertj.core.api.Assertions.assertThat(requestCaptor.getValue().getNotificationIds())
                .containsExactly(10L, 11L);
    }

    @Test
    void invalidSelectedReadRequestReturnsBadRequest() throws Exception {
        mockMvc.perform(patch("/api/notifications/read")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"notificationIds\":[]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void unreadCountReturnsOk() throws Exception {
        when(notificationService.getUnreadCount())
                .thenReturn(UnreadNotificationCountResponse.builder().count(5).build());

        mockMvc.perform(get("/api/notifications/unread-count")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(5));
    }

    @Test
    void invalidEnumFilterReturnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/notifications?type=BAD_TYPE")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void typeFilterIsPassedToService() throws Exception {
        when(notificationService.getMyNotifications(
                0,
                10,
                true,
                NotificationType.REPORT_ASSIGNED,
                "createdAt",
                "DESC"))
                .thenReturn(PageResponse.<NotificationResponse>builder().content(List.of()).build());

        mockMvc.perform(get("/api/notifications?unread=true&type=REPORT_ASSIGNED&sortBy=createdAt&direction=DESC")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk());
    }
}
