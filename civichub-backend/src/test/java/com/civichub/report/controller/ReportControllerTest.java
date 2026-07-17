package com.civichub.report.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.report.dto.response.ReportDetailResponse;
import com.civichub.report.service.ReportService;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(ReportController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class ReportControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ReportService reportService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void unauthenticatedCreateShouldReturnUnauthorized() throws Exception {
        mockMvc.perform(post("/api/reports")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validCreateBody()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedCitizenCreateShouldReturnCreated() throws Exception {
        when(reportService.createReport(any())).thenReturn(detailResponse());

        mockMvc.perform(post("/api/reports")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(validCreateBody()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(99));
    }

    @Test
    void invalidCreateBodyShouldReturnBadRequest() throws Exception {
        mockMvc.perform(post("/api/reports")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void anotherCitizenReportShouldReturnNotFound() throws Exception {
        when(reportService.getMyReport(99L)).thenThrow(new ResourceNotFoundException("Report not found"));

        mockMvc.perform(get("/api/reports/my/99")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isNotFound());
    }

    @Test
    void cancelShouldReturnOk() throws Exception {
        when(reportService.cancelMyReport(99L)).thenReturn(detailResponse());

        mockMvc.perform(patch("/api/reports/my/99/cancel")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(99));
    }

    private String validCreateBody() {
        return """
                {
                  "title": "Broken light",
                  "description": "Street light is broken",
                  "address": "123 Main Street",
                  "categoryId": 10,
                  "imageUrls": ["https://a.test/1.png"]
                }
                """;
    }

    private ReportDetailResponse detailResponse() {
        return ReportDetailResponse.builder().id(99L).title("Broken light").build();
    }
}
