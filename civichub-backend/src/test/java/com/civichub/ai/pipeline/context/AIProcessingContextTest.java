package com.civichub.ai.pipeline.context;

import static org.assertj.core.api.Assertions.assertThat;

import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class AIProcessingContextTest {

    @Test
    void carriesGenericMetadataWithoutProviderSpecificFields() {
        AIProcessingContext context = AIProcessingContext.builder()
                .requestId("pipe-1")
                .provider("LOCAL")
                .imagePath(Path.of("uploads/report-images/street.png"))
                .mimeType("image/png")
                .reportId(10L)
                .citizenId(20L)
                .locale("vi-VN")
                .traceId("trace-1")
                .metadata(Map.of("futureKey", "futureValue"))
                .build();

        assertThat(context.getRequestId()).isEqualTo("pipe-1");
        assertThat(context.getMetadata()).containsEntry("futureKey", "futureValue");
        assertThat(context.getReportId()).isEqualTo(10L);
        assertThat(context.getCitizenId()).isEqualTo(20L);
    }
}
