package com.civichub.ai.ops.rate;

import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import jakarta.servlet.FilterChain;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

class AIRateLimitFilterTest {

    private final AIRateLimiter rateLimiter = Mockito.mock(AIRateLimiter.class);
    private final AIRateLimitFilter filter = new AIRateLimitFilter(
            rateLimiter,
            new ObjectMapper().registerModule(new JavaTimeModule()));

    @AfterEach
    void clearSecurityContext() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void productAiEndpointReturnsTooManyRequestsWhenLimited() throws Exception {
        SecurityContextHolder.getContext()
                .setAuthentication(new UsernamePasswordAuthenticationToken("citizen@example.com", null));
        when(rateLimiter.allow("citizen@example.com")).thenReturn(false);
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/ai/reports/description-suggestion");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = Mockito.mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(rateLimiter).allow("citizen@example.com");
        verify(chain, never()).doFilter(request, response);
        org.assertj.core.api.Assertions.assertThat(response.getStatus()).isEqualTo(429);
        org.assertj.core.api.Assertions.assertThat(response.getContentAsString()).contains("AI rate limit exceeded");
    }

    @Test
    void nonProductAiEndpointBypassesLimiter() throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/internal/ai/report-summary");
        MockHttpServletResponse response = new MockHttpServletResponse();
        FilterChain chain = Mockito.mock(FilterChain.class);

        filter.doFilter(request, response, chain);

        verify(rateLimiter, never()).allow(Mockito.anyString());
        verify(chain).doFilter(request, response);
    }
}
