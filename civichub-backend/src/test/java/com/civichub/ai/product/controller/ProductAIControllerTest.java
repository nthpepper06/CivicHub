package com.civichub.ai.product.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.ai.exception.AITimeoutException;
import com.civichub.ai.product.dto.response.ImageContextSuggestionResponse;
import com.civichub.ai.product.dto.response.TextSuggestionResponse;
import com.civichub.ai.product.service.ProductAIService;
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

@WebMvcTest(ProductAIController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class ProductAIControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private ProductAIService productAIService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void citizenCanRequestDescriptionSuggestion() throws Exception {
        when(productAIService.improveReportDescription(any())).thenReturn(TextSuggestionResponse.builder()
                .requestId("req-1")
                .suggestion("Clearer report description.")
                .provider("OPENAI")
                .model("gpt-test")
                .build());

        mockMvc.perform(post("/api/ai/reports/description-suggestion")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "description": "bad paving"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.suggestion").value("Clearer report description."))
                .andExpect(jsonPath("$.data.provider").value("OPENAI"));
    }

    @Test
    void citizenCanRequestImageContext() throws Exception {
        when(productAIService.describeImageContext(any())).thenReturn(ImageContextSuggestionResponse.builder()
                .requestId("req-2")
                .suggestion("Image shows damaged pavement.")
                .confidence(null)
                .provider("OPENAI")
                .model("gpt-test")
                .build());

        mockMvc.perform(post("/api/ai/reports/image-context")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "imageUrl": "/uploads/report-images/path.png"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.suggestion").value("Image shows damaged pavement."))
                .andExpect(jsonPath("$.data.confidence").doesNotExist());
    }

    @Test
    void staffCanRequestResolutionSuggestion() throws Exception {
        when(productAIService.improveResolutionSummary(any())).thenReturn(TextSuggestionResponse.builder()
                .requestId("req-3")
                .suggestion("Resolved by replacing damaged panel.")
                .provider("OPENAI")
                .model("gpt-test")
                .build());

        mockMvc.perform(post("/api/ai/staff/resolution-summary-suggestion")
                        .with(user("staff@example.com").roles("STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "summary": "fixed panel"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.suggestion").value("Resolved by replacing damaged panel."));
    }

    @Test
    void anonymousCannotUseProductAI() throws Exception {
        mockMvc.perform(post("/api/ai/reports/description-suggestion")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "description": "bad paving"
                                }
                                """))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void citizenCannotUseStaffResolutionSuggestion() throws Exception {
        mockMvc.perform(post("/api/ai/staff/resolution-summary-suggestion")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "summary": "fixed panel"
                                }
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void validationFailureDoesNotCallService() throws Exception {
        mockMvc.perform(post("/api/ai/reports/description-suggestion")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "",
                                  "description": ""
                                }
                                """))
                .andExpect(status().isBadRequest());

        verifyNoInteractions(productAIService);
    }

    @Test
    void timeoutMapsToSafeError() throws Exception {
        when(productAIService.improveReportDescription(any()))
                .thenThrow(new AITimeoutException());

        mockMvc.perform(post("/api/ai/reports/description-suggestion")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Broken sidewalk",
                                  "description": "bad paving"
                                }
                                """))
                .andExpect(status().isGatewayTimeout())
                .andExpect(jsonPath("$.message").value("AI provider request timed out"));
    }
}
