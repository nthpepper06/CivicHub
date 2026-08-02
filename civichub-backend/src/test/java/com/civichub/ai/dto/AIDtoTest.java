package com.civichub.ai.dto;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class AIDtoTest {

    @Test
    void mapsProviderIndependentRequestResponseUsageAndError() {
        AIRequest request = AIRequest.builder()
                .input("input")
                .correlationId("req-1")
                .build();
        AIUsage usage = AIUsage.builder()
                .inputTokens(2)
                .outputTokens(3)
                .totalTokens(5)
                .build();
        AIResponse response = AIResponse.builder()
                .output("output")
                .provider("LOCAL")
                .model("local")
                .usage(usage)
                .build();
        AIError error = AIError.builder()
                .code("AI_TIMEOUT")
                .message("AI provider request timed out")
                .provider("LOCAL")
                .build();

        assertThat(request.getCorrelationId()).isEqualTo("req-1");
        assertThat(response.getUsage().getTotalTokens()).isEqualTo(5);
        assertThat(error.getCode()).isEqualTo("AI_TIMEOUT");
    }
}
