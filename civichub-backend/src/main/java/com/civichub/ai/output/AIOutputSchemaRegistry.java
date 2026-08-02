package com.civichub.ai.output;

public interface AIOutputSchemaRegistry {

    AIStructuredOutputDefinition resolve(String schemaId, String version);
}
