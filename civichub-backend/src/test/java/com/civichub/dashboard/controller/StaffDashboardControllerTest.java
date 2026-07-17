package com.civichub.dashboard.controller;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.StaffDashboardSummaryResponse;
import com.civichub.dashboard.service.DashboardService;
import com.civichub.report.dto.response.ReportSummaryResponse;
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
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(StaffDashboardController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class StaffDashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DashboardService dashboardService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void staffCanGetDashboardSummary() throws Exception {
        when(dashboardService.getStaffSummary()).thenReturn(StaffDashboardSummaryResponse.builder()
                .pendingReports(1)
                .receivedReports(2)
                .totalAssigned(3)
                .build());

        mockMvc.perform(get("/api/staff/dashboard/summary")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pendingReports").value(1))
                .andExpect(jsonPath("$.data.receivedReports").value(2))
                .andExpect(jsonPath("$.data.totalAssigned").value(3));
    }

    @Test
    void staffCanGetRecentReports() throws Exception {
        when(dashboardService.getStaffRecentReports(10))
                .thenReturn(PageResponse.<ReportSummaryResponse>builder()
                        .content(List.of(ReportSummaryResponse.builder().id(99L).build()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/staff/dashboard/recent")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(99));
    }

    @Test
    void citizenReceivesForbiddenForStaffDashboard() throws Exception {
        mockMvc.perform(get("/api/staff/dashboard/summary")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousReceivesUnauthorizedForStaffDashboard() throws Exception {
        mockMvc.perform(get("/api/staff/dashboard/summary"))
                .andExpect(status().isUnauthorized());
    }
}
