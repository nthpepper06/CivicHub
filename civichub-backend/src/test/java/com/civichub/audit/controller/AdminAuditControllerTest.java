package com.civichub.audit.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.audit.dto.response.AuditLogDetailResponse;
import com.civichub.audit.dto.response.AuditLogSummaryResponse;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.audit.service.AuditService;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import java.time.LocalDateTime;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdminAuditController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AdminAuditControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AuditService auditService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanListAuditLogs() throws Exception {
        when(auditService.getAuditLogs(
                0,
                20,
                AuditAction.CATEGORY_CREATED,
                AuditEntityType.CATEGORY,
                1L,
                7L,
                UserRole.ADMIN,
                null,
                null,
                "category",
                "createdAt",
                "DESC"))
                .thenReturn(PageResponse.<AuditLogSummaryResponse>builder()
                        .content(List.of(AuditLogSummaryResponse.builder()
                                .id(10L)
                                .action(AuditAction.CATEGORY_CREATED)
                                .build()))
                        .page(0)
                        .size(20)
                        .build());

        mockMvc.perform(get("/api/admin/audit-logs?action=CATEGORY_CREATED&entityType=CATEGORY"
                        + "&entityId=1&actorId=7&actorRole=ADMIN&search=category&sortBy=createdAt&direction=DESC")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(10))
                .andExpect(jsonPath("$.data.content[0].action").value("CATEGORY_CREATED"));
    }

    @Test
    void adminCanViewAuditLogDetail() throws Exception {
        when(auditService.getAuditLog(10L)).thenReturn(AuditLogDetailResponse.builder()
                .id(10L)
                .oldValues("{\"status\":\"PENDING\"}")
                .newValues("{\"status\":\"CANCELLED\"}")
                .build());

        mockMvc.perform(get("/api/admin/audit-logs/10")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(10))
                .andExpect(jsonPath("$.data.newValues").value("{\"status\":\"CANCELLED\"}"));
    }

    @Test
    void staffReceivesForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/audit-logs")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isForbidden());
    }

    @Test
    void citizenReceivesForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/audit-logs")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousReceivesUnauthorized() throws Exception {
        mockMvc.perform(get("/api/admin/audit-logs"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void invalidEnumFilterReturnsBadRequest() throws Exception {
        mockMvc.perform(get("/api/admin/audit-logs?action=BAD_ACTION")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void invalidDateRangeReturnsBadRequest() throws Exception {
        when(auditService.getAuditLogs(
                anyInt(),
                anyInt(),
                any(),
                any(),
                any(),
                any(),
                any(),
                any(LocalDateTime.class),
                any(LocalDateTime.class),
                any(),
                any(),
                any()))
                .thenThrow(new IllegalArgumentException("Invalid date range"));

        mockMvc.perform(get("/api/admin/audit-logs?createdFrom=2026-01-02T00:00:00&createdTo=2026-01-01T00:00:00")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isBadRequest());
    }

    @Test
    void missingDetailReturnsNotFound() throws Exception {
        when(auditService.getAuditLog(404L)).thenThrow(new ResourceNotFoundException("Audit log not found"));

        mockMvc.perform(get("/api/admin/audit-logs/404")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isNotFound());
    }

    @Test
    void postEndpointIsNotExposed() throws Exception {
        mockMvc.perform(post("/api/admin/audit-logs")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isMethodNotAllowed());
    }

    @Test
    void putEndpointIsNotExposed() throws Exception {
        mockMvc.perform(put("/api/admin/audit-logs/10")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isMethodNotAllowed());
    }

    @Test
    void deleteEndpointIsNotExposed() throws Exception {
        mockMvc.perform(delete("/api/admin/audit-logs/10")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isMethodNotAllowed());
    }
}
