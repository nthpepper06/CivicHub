package com.civichub.ai.pipeline.preprocess;

import com.civichub.ai.pipeline.context.AIProcessingContext;
import com.civichub.ai.pipeline.storage.StoredAIImage;
import org.springframework.stereotype.Component;

@Component
public class PassThroughAIImagePreprocessor implements AIImagePreprocessor {

    @Override
    public PreprocessedAIImage preprocess(StoredAIImage image, AIProcessingContext context) {
        return PreprocessedAIImage.builder()
                .path(image.getPath())
                .mimeType(image.getMimeType())
                .sizeBytes(image.getSizeBytes())
                .metadata(java.util.Map.of("preprocessed", false))
                .build();
    }
}
