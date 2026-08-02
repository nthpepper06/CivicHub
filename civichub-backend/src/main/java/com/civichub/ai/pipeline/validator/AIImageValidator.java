package com.civichub.ai.pipeline.validator;

import com.civichub.ai.pipeline.storage.StoredAIImage;

public interface AIImageValidator {

    void validate(StoredAIImage image);
}
