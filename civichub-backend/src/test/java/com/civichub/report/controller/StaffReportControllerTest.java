package com.civichub.report.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.common.exception.InvalidReportStateException;
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
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(StaffReportController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class StaffReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReportService reportService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void staffCanListDepartmentReports() throws Exception {
        when(reportService.getStaffReports(0, 10, null, null, null, null, null, null))
                .thenReturn(PageResponse.<ReportSummaryResponse>builder()
                        .content(List.of(ReportSummaryResponse.builder().id(99L).build()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/staff/reports")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(99));
    }

    @Test
    void citizenReceivesForbiddenForStaffEndpoint() throws Exception {
        mockMvc.perform(get("/api/staff/reports")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void unauthenticatedReceivesUnauthorizedForStaffEndpoint() throws Exception {
        mockMvc.perform(get("/api/staff/reports"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void validStatusUpdateReturnsOk() throws Exception {
        when(reportService.updateStaffReportStatus(any(), any()))
                .thenReturn(ReportDetailResponse.builder().id(99L).build());

        mockMvc.perform(patch("/api/staff/reports/99/status")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "IN_PROGRESS"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(99));
    }

    @Test
    void invalidTransitionReturnsConflict() throws Exception {
        when(reportService.updateStaffReportStatus(any(), any()))
                .thenThrow(new InvalidReportStateException("Invalid report status transition"));

        mockMvc.perform(patch("/api/staff/reports/99/status")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "status": "RESOLVED"
                                }
                                """))
                .andExpect(status().isConflict());
    }
}
