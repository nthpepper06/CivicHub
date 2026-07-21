package com.civichub.report.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.dto.response.ReportSummaryResponse;
import com.civichub.report.service.ReportService;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdminReportController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AdminReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReportService reportService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanListReports() throws Exception {
        when(reportService.getAdminReports(0, 10, null, null, null, null, null, null, null, null, null, null))
                .thenReturn(PageResponse.<ReportSummaryResponse>builder()
                        .content(List.of(ReportSummaryResponse.builder().id(99L).build()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/admin/reports")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(99));
    }

    @Test
    void adminCanAssignDepartment() throws Exception {
        when(reportService.assignDepartment(any(), any()))
                .thenReturn(ReportDetailResponse.builder().id(99L).departmentId(5L).build());

        mockMvc.perform(patch("/api/admin/reports/99/department")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "departmentId": 5
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.departmentId").value(5));
    }

    @Test
    void adminCanUpdateReportStatus() throws Exception {
        when(reportService.updateAdminReportStatus(any(), any()))
                .thenReturn(ReportDetailResponse.builder()
                        .id(99L)
                        .status(com.civichub.common.enums.ReportStatus.RECEIVED)
                        .build());

        mockMvc.perform(patch("/api/admin/reports/99/status")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"status\":\"RECEIVED\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("RECEIVED"));
    }

    @Test
    void adminCanExportReports() throws Exception {
        when(reportService.exportAdminReportsCsv(
                null, null, null, null, null, null, null, null, null, null))
                .thenReturn("\ufeffID,Title\n99,'=SUM(A1:A2)");

        mockMvc.perform(get("/api/admin/reports/export")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/csv"))
                .andExpect(header().string(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"civichub-reports.csv\""))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("'=SUM")));
    }

    @Test
    void staffReceivesForbiddenForAdminReports() throws Exception {
        mockMvc.perform(get("/api/admin/reports")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isForbidden());
    }

    @Test
    void citizenReceivesForbiddenForAdminReports() throws Exception {
        mockMvc.perform(get("/api/admin/reports")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedReceivesUnauthorizedForAdminReports() throws Exception {
        mockMvc.perform(get("/api/admin/reports"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void invalidDepartmentRequestReturnsBadRequest() throws Exception {
        mockMvc.perform(patch("/api/admin/reports/99/department")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }
}
