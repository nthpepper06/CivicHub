package com.civichub.ai.output;

import com.civichub.ai.dto.AIResponse;
import java.util.Map;

public interface AIOutputMapper {

    Map<String, Object> mapJsonObject(AIResponse response, AIStructuredOutputDefinition definition);
}
