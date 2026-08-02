package com.civichub.ai.pipeline.context;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder(toBuilder = true)
@NoArgsConstructor
@AllArgsConstructor
public class AIProcessingContext {

    private String requestId;
    private String provider;
    private Path imagePath;
    private String imageReference;
    private String mimeType;
    private Long reportId;
    private Long citizenId;
    private String locale;
    private String traceId;

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
}
