package com.civichub.ai.pipeline.preprocess;

import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class PreprocessedAIImage {

    private final Path path;
    private final String mimeType;
    private final long sizeBytes;

    @Builder.Default
    private final Map<String, Object> metadata = new HashMap<>();
}
