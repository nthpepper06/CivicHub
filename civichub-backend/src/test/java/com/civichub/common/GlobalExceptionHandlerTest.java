package com.civichub.common;

import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.ai.exception.AIInvalidApiKeyException;
import com.civichub.ai.exception.AITimeoutException;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

class GlobalExceptionHandlerTest {

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(new TestController())
                .setControllerAdvice(new GlobalExceptionHandler())
                .build();
    }

    @Test
    void unexpectedExceptionShouldReturnGenericInternalServerError() throws Exception {
        mockMvc.perform(get("/test/unexpected-error"))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.message").value("Internal server error"))
                .andExpect(jsonPath("$.message").value(not(containsString("database constraint leaked"))));
    }

    @Test
    void illegalArgumentShouldNotExposeOriginalMessage() throws Exception {
        mockMvc.perform(get("/test/illegal-argument"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Invalid request"))
                .andExpect(jsonPath("$.message").value(not(containsString("internal validation detail"))));
    }

    @Test
    void auditActionCheckViolationShouldReturnSafeBusinessReason() throws Exception {
        mockMvc.perform(get("/test/audit-action-check"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value(
                        "Audit logging is not synchronized for this report assignment. Please sync audit log constraints and retry."))
                .andExpect(jsonPath("$.message").value(not(containsString("check constraint"))));
    }

    @Test
    void genericDataIntegrityShouldKeepGenericMessage() throws Exception {
        mockMvc.perform(get("/test/generic-data-integrity"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message").value("Resource already exists or violates data constraints"));
    }

    @Test
    void aiTimeoutShouldReturnSafeGatewayTimeout() throws Exception {
        mockMvc.perform(get("/test/ai-timeout"))
                .andExpect(status().isGatewayTimeout())
                .andExpect(jsonPath("$.message").value("AI provider request timed out"));
    }

    @Test
    void aiInvalidApiKeyShouldNotExposeSecret() throws Exception {
        mockMvc.perform(get("/test/ai-invalid-key"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("AI provider authentication failed"))
                .andExpect(jsonPath("$.message").value(not(containsString("secret-key"))));
    }

    @RestController
    private static class TestController {

        @GetMapping("/test/unexpected-error")
        void unexpectedError() {
            throw new RuntimeException("database constraint leaked");
        }

        @GetMapping("/test/illegal-argument")
        void illegalArgument() {
            throw new IllegalArgumentException("internal validation detail");
        }

        @GetMapping("/test/audit-action-check")
        void auditActionCheck() {
            throw new DataIntegrityViolationException(
                    "could not execute statement; violates check constraint \"audit_logs_action_check\"");
        }

        @GetMapping("/test/generic-data-integrity")
        void genericDataIntegrity() {
            throw new DataIntegrityViolationException("duplicate key value violates unique constraint");
        }

        @GetMapping("/test/ai-timeout")
        void aiTimeout() {
            throw new AITimeoutException();
        }

        @GetMapping("/test/ai-invalid-key")
        void aiInvalidKey() {
            throw new AIInvalidApiKeyException();
        }
    }
}
