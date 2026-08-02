package com.civichub.ai.pipeline.storage;

import java.nio.file.Path;
import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class StoredAIImage {

    private final String reference;
    private final Path path;
    private final String mimeType;
    private final long sizeBytes;
}
