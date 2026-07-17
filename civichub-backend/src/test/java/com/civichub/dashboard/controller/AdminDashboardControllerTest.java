package com.civichub.dashboard.controller;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.dashboard.dto.response.CategoryStatisticResponse;
import com.civichub.dashboard.dto.response.DashboardSummaryResponse;
import com.civichub.dashboard.dto.response.DepartmentStatisticResponse;
import com.civichub.dashboard.dto.response.MonthlyStatisticResponse;
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

@WebMvcTest(AdminDashboardController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AdminDashboardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DashboardService dashboardService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanGetDashboardSummary() throws Exception {
        when(dashboardService.getAdminSummary()).thenReturn(DashboardSummaryResponse.builder()
                .totalReports(9)
                .pendingReports(1)
                .totalCitizens(3)
                .build());

        mockMvc.perform(get("/api/admin/dashboard/summary")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalReports").value(9))
                .andExpect(jsonPath("$.data.pendingReports").value(1))
                .andExpect(jsonPath("$.data.totalCitizens").value(3));
    }

    @Test
    void adminCanGetCategoryStatistics() throws Exception {
        when(dashboardService.getCategoryStatistics())
                .thenReturn(List.of(CategoryStatisticResponse.builder()
                        .categoryId(1L)
                        .categoryName("Environment")
                        .totalReports(35)
                        .build()));

        mockMvc.perform(get("/api/admin/dashboard/category")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].categoryId").value(1))
                .andExpect(jsonPath("$.data[0].totalReports").value(35));
    }

    @Test
    void adminCanGetDepartmentStatistics() throws Exception {
        when(dashboardService.getDepartmentStatistics())
                .thenReturn(List.of(DepartmentStatisticResponse.builder()
                        .departmentId(2L)
                        .departmentName("Urban Services")
                        .totalReports(12)
                        .build()));

        mockMvc.perform(get("/api/admin/dashboard/department")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].departmentId").value(2))
                .andExpect(jsonPath("$.data[0].totalReports").value(12));
    }

    @Test
    void adminCanGetMonthlyStatistics() throws Exception {
        when(dashboardService.getMonthlyStatistics(2026)).thenReturn(List.of(
                MonthlyStatisticResponse.builder()
                        .month(1)
                        .totalReports(5)
                        .resolvedReports(2)
                        .build()));

        mockMvc.perform(get("/api/admin/dashboard/monthly?year=2026")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].month").value(1))
                .andExpect(jsonPath("$.data[0].resolvedReports").value(2));
    }

    @Test
    void adminCanGetRecentReports() throws Exception {
        when(dashboardService.getAdminRecentReports(10))
                .thenReturn(PageResponse.<ReportSummaryResponse>builder()
                        .content(List.of(ReportSummaryResponse.builder().id(99L).build()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/admin/dashboard/recent")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].id").value(99));
    }

    @Test
    void staffReceivesForbiddenForAdminDashboard() throws Exception {
        mockMvc.perform(get("/api/admin/dashboard/summary")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousReceivesUnauthorizedForAdminDashboard() throws Exception {
        mockMvc.perform(get("/api/admin/dashboard/summary"))
                .andExpect(status().isUnauthorized());
    }
}
