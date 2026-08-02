package com.civichub.ai.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.ai.dto.response.ImageContextAIResponse;
import com.civichub.ai.dto.response.ReportSummaryAIResponse;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.service.InternalAIUseCaseService;
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

@WebMvcTest(InternalAIController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class InternalAIControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private InternalAIUseCaseService internalAIUseCaseService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void staffCanGenerateReportSummary() throws Exception {
        when(internalAIUseCaseService.summarizeReport(any())).thenReturn(ReportSummaryAIResponse.builder()
                .requestId("req-1")
                .summary("Streetlight outage reported.")
                .provider("OPENAI")
                .model("gpt-test")
                .taskType("REPORT_SUMMARY")
                .templateId("REPORT_SUMMARY_V1")
                .templateVersion("v1")
                .outputSchemaId("report_summary")
                .outputSchemaVersion("v1")
                .build());

        mockMvc.perform(post("/api/internal/ai/report-summary")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken streetlight",
                                  "description": "Lamp is out"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.summary").value("Streetlight outage reported."))
                .andExpect(jsonPath("$.data.provider").value("OPENAI"))
                .andExpect(jsonPath("$.data.taskType").value("REPORT_SUMMARY"));
    }

    @Test
    void adminCanGenerateImageContext() throws Exception {
        when(internalAIUseCaseService.describeImageContext(any())).thenReturn(ImageContextAIResponse.builder()
                .requestId("req-2")
                .context("Image context placeholder.")
                .provider("OPENAI")
                .model("gpt-test")
                .taskType("IMAGE_CONTEXT")
                .templateId("IMAGE_CONTEXT_V1")
                .templateVersion("v1")
                .outputSchemaId("image_context")
                .outputSchemaVersion("v1")
                .build());

        mockMvc.perform(post("/api/internal/ai/image-context")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken streetlight",
                                  "imageUrl": "/uploads/report-images/street.png"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.context").value("Image context placeholder."))
                .andExpect(jsonPath("$.data.taskType").value("IMAGE_CONTEXT"));
    }

    @Test
    void citizenCannotUseInternalAIEndpoint() throws Exception {
        mockMvc.perform(post("/api/internal/ai/report-summary")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken streetlight",
                                  "description": "Lamp is out"
                                }
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousCannotUseInternalAIEndpoint() throws Exception {
        mockMvc.perform(post("/api/internal/ai/report-summary")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken streetlight",
                                  "description": "Lamp is out"
                                }
                                """))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void validationFailureDoesNotCallUseCase() throws Exception {
        mockMvc.perform(post("/api/internal/ai/report-summary")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "",
                                  "description": ""
                                }
                                """))
                .andExpect(status().isBadRequest());
    }

    @Test
    void providerFailureReturnsSafeError() throws Exception {
        when(internalAIUseCaseService.summarizeReport(any()))
                .thenThrow(new AIProviderUnavailableException("OPENAI"));

        mockMvc.perform(post("/api/internal/ai/report-summary")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken streetlight",
                                  "description": "Lamp is out"
                                }
                                """))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.message").value("Configured AI provider is not available: OPENAI"));
    }
}
