package com.civichub.ai.logging;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIUsage;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

@ExtendWith(OutputCaptureExtension.class)
class AILoggerTest {

    private final AILogger logger = new AILogger();

    @Test
    void requestLoggingIncludesMetadataButNotSensitiveContent(CapturedOutput output) {
        AIRequest request = AIRequest.builder()
                .correlationId("req-1")
                .taskType("REPORT_SUMMARY")
                .templateId("REPORT_SUMMARY_V1")
                .outputSchemaId("report_summary")
                .systemContent("secret system prompt")
                .userContent("raw citizen description")
                .model("gpt-test")
                .build();
        AIResponse response = AIResponse.builder()
                .model("gpt-test")
                .usage(AIUsage.builder().totalTokens(10).build())
                .build();

        logger.success("OPENAI", 25, request, response);
        logger.failure("OPENAI", 30, request, "AI_TIMEOUT");

        assertThat(output).contains("taskType=REPORT_SUMMARY");
        assertThat(output).contains("templateId=REPORT_SUMMARY_V1");
        assertThat(output).contains("schemaId=report_summary");
        assertThat(output).doesNotContain("secret system prompt");
        assertThat(output).doesNotContain("raw citizen description");
    }
}
