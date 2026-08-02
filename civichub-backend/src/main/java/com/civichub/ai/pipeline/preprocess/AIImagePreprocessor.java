package com.civichub.ai.pipeline.preprocess;

import com.civichub.ai.pipeline.context.AIProcessingContext;
import com.civichub.ai.pipeline.storage.StoredAIImage;

public interface AIImagePreprocessor {

    PreprocessedAIImage preprocess(StoredAIImage image, AIProcessingContext context);
}
