package com.civichub.ai.logging;

import static org.assertj.core.api.Assertions.assertThat;

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
    void successLogIncludesProviderLatencyAndUsageButNotInput(CapturedOutput output) {
        logger.success(
                "LOCAL",
                25,
                AIResponse.builder()
                        .usage(AIUsage.builder().totalTokens(9).build())
                        .build());

        assertThat(output).contains("provider=LOCAL");
        assertThat(output).contains("latencyMs=25");
        assertThat(output).contains("totalTokens=9");
        assertThat(output).doesNotContain("sensitive user input");
    }

    @Test
    void failureLogIncludesProviderAndCode(CapturedOutput output) {
        logger.failure("LOCAL", 30, "AI_TIMEOUT");

        assertThat(output).contains("provider=LOCAL");
        assertThat(output).contains("success=false");
        assertThat(output).contains("errorCode=AI_TIMEOUT");
    }

    @Test
    void pipelineLogsIncludeStageButNotImageContent(CapturedOutput output) {
        logger.pipelineStage("pipe-1", "LOCAL", "validation", 7, true);
        logger.pipelineFailure("pipe-1", "LOCAL", "storage", 8, "AI_STORAGE_UNAVAILABLE");

        assertThat(output).contains("ai_pipeline");
        assertThat(output).contains("requestId=pipe-1");
        assertThat(output).contains("stage=validation");
        assertThat(output).contains("stage=storage");
        assertThat(output).doesNotContain("raw image bytes");
    }
}
