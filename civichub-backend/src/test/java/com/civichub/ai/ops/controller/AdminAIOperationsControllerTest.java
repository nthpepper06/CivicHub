package com.civichub.ai.ops.controller;

import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.ai.ops.dto.AIHealthResponse;
import com.civichub.ai.ops.dto.AIProviderOperationsResponse;
import com.civichub.ai.ops.dto.AIUsageSummaryResponse;
import com.civichub.ai.ops.service.AIOperationsService;
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

@WebMvcTest(AdminAIOperationsController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AdminAIOperationsControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AIOperationsService operationsService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanReadUsage() throws Exception {
        when(operationsService.usage()).thenReturn(AIUsageSummaryResponse.builder()
                .requestCount(3)
                .successCount(2)
                .failureCount(1)
                .averageLatencyMs(125.0)
                .estimatedTotalTokens(42)
                .estimatedCost(0.01)
                .build());

        mockMvc.perform(get("/api/admin/ai/usage")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.requestCount").value(3))
                .andExpect(jsonPath("$.data.failureCount").value(1));
    }

    @Test
    void adminCanReadProviderHealthWithoutSecrets() throws Exception {
        when(operationsService.providers()).thenReturn(AIProviderOperationsResponse.builder()
                .configuredProvider("OPENAI")
                .aiEnabled(true)
                .availableProviders(List.of("OPENAI"))
                .model("gpt-test")
                .timeoutMs(5000)
                .retryMaxAttempts(2)
                .build());
        when(operationsService.health()).thenReturn(AIHealthResponse.builder()
                .aiModuleEnabled(true)
                .configuredProvider("OPENAI")
                .providerEnabled(true)
                .configurationValid(true)
                .model("gpt-test")
                .build());

        mockMvc.perform(get("/api/admin/ai/providers")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.configuredProvider").value("OPENAI"))
                .andExpect(jsonPath("$.data.model").value("gpt-test"))
                .andExpect(jsonPath("$.data.apiKey").doesNotExist());

        mockMvc.perform(get("/api/admin/ai/health")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.configurationValid").value(true))
                .andExpect(jsonPath("$.data.apiKey").doesNotExist());
    }

    @Test
    void staffCannotReadAdminAiOperations() throws Exception {
        mockMvc.perform(get("/api/admin/ai/usage")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousCannotReadAdminAiOperations() throws Exception {
        mockMvc.perform(get("/api/admin/ai/usage"))
                .andExpect(status().isUnauthorized());
    }
}
