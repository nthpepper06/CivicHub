package com.civichub.ai.output;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.StructuredOutputDefinitionException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
@RequiredArgsConstructor
public class DefaultAIOutputMapper implements AIOutputMapper {

    private final ObjectMapper objectMapper;

    @Override
    public Map<String, Object> mapJsonObject(AIResponse response, AIStructuredOutputDefinition definition) {
        if (definition.getType() != AIOutputType.JSON_OBJECT) {
            throw new StructuredOutputDefinitionException("Structured output schema is not a JSON object");
        }
        if (response == null || !StringUtils.hasText(response.getOutput())) {
            throw new StructuredOutputDefinitionException("AI provider returned empty structured output");
        }
        Map<String, Object> payload;
        try {
            payload = objectMapper.readValue(response.getOutput(), new TypeReference<>() {});
        } catch (Exception exception) {
            throw new StructuredOutputDefinitionException("AI provider returned invalid JSON output");
        }
        validate(payload, definition);
        return payload;
    }

    private void validate(Map<String, Object> payload, AIStructuredOutputDefinition definition) {
        Set<String> allowedFields = definition.getFields().stream()
                .map(AIOutputField::getName)
                .collect(Collectors.toSet());
        for (String field : payload.keySet()) {
            if (!allowedFields.contains(field)) {
                throw new StructuredOutputDefinitionException("AI provider returned unknown structured output field");
            }
        }
        for (AIOutputField field : definition.getFields()) {
            Object value = payload.get(field.getName());
            if (field.isRequired() && value == null) {
                throw new StructuredOutputDefinitionException("AI provider output is missing a required field");
            }
            if (value != null) {
                validateType(field, value);
                if (field.getMaxLength() != null
                        && value instanceof String text
                        && text.length() > field.getMaxLength()) {
                    throw new StructuredOutputDefinitionException("AI provider output field exceeds maximum length");
                }
                if (field.getEnumValues() != null
                        && !field.getEnumValues().isEmpty()
                        && !field.getEnumValues().contains(String.valueOf(value))) {
                    throw new StructuredOutputDefinitionException("AI provider output field violates enum constraints");
                }
            }
        }
    }

    private void validateType(AIOutputField field, Object value) {
        boolean valid = switch (field.getType()) {
            case STRING -> value instanceof String;
            case INTEGER -> value instanceof Integer || value instanceof Long;
            case NUMBER -> value instanceof Number;
            case BOOLEAN -> value instanceof Boolean;
            case ARRAY -> value instanceof java.util.List<?>;
            case OBJECT -> value instanceof Map<?, ?>;
        };
        if (!valid) {
            throw new StructuredOutputDefinitionException("AI provider output field has an invalid type");
        }
    }
}
