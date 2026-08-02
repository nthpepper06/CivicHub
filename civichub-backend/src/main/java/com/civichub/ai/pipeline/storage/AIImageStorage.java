package com.civichub.ai.pipeline.storage;

public interface AIImageStorage {

    StoredAIImage resolve(String imageReference);
}
