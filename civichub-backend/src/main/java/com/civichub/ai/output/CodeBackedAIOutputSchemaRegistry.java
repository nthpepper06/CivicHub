package com.civichub.ai.output;

import com.civichub.ai.exception.StructuredOutputDefinitionException;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class CodeBackedAIOutputSchemaRegistry implements AIOutputSchemaRegistry {

    private final Map<String, AIStructuredOutputDefinition> schemas;

    public CodeBackedAIOutputSchemaRegistry() {
        this(defaultSchemas());
    }

    public CodeBackedAIOutputSchemaRegistry(Collection<AIStructuredOutputDefinition> definitions) {
        this.schemas = definitions.stream()
                .peek(this::validate)
                .collect(Collectors.toUnmodifiableMap(
                        definition -> key(definition.getSchemaId(), definition.getVersion()),
                        Function.identity(),
                        (left, right) -> {
                            throw new StructuredOutputDefinitionException("Duplicate structured output schema");
                        }));
    }

    @Override
    public AIStructuredOutputDefinition resolve(String schemaId, String version) {
        AIStructuredOutputDefinition definition = schemas.get(key(schemaId, version));
        if (definition == null) {
            throw new StructuredOutputDefinitionException("Structured output schema was not found");
        }
        return definition;
    }

    private void validate(AIStructuredOutputDefinition definition) {
        if (!StringUtils.hasText(definition.getSchemaId()) || !StringUtils.hasText(definition.getVersion())) {
            throw new StructuredOutputDefinitionException("Structured output schema requires id and version");
        }
        Set<String> fieldNames = definition.getFields().stream()
                .map(AIOutputField::getName)
                .collect(Collectors.toSet());
        if (fieldNames.size() != definition.getFields().size()) {
            throw new StructuredOutputDefinitionException("Duplicate structured output field");
        }
        for (AIOutputField field : definition.getFields()) {
            if (!StringUtils.hasText(field.getName())) {
                throw new StructuredOutputDefinitionException("Structured output field requires a name");
            }
            if (field.getEnumValues() != null
                    && !field.getEnumValues().isEmpty()
                    && field.getType() != AIOutputFieldType.STRING) {
                throw new StructuredOutputDefinitionException("Enum constraints are only supported for string fields");
            }
        }
    }

    private static String key(String schemaId, String version) {
        return schemaId + ":" + version;
    }

    private static List<AIStructuredOutputDefinition> defaultSchemas() {
        return List.of(
                AIStructuredOutputDefinition.builder()
                        .schemaId("plain_text")
                        .version("v1")
                        .type(AIOutputType.PLAIN_TEXT)
                        .build(),
                AIStructuredOutputDefinition.builder()
                        .schemaId("report_summary")
                        .version("v1")
                        .type(AIOutputType.JSON_OBJECT)
                        .field(AIOutputField.builder()
                                .name("summary")
                                .type(AIOutputFieldType.STRING)
                                .required(true)
                                .maxLength(500)
                                .build())
                        .build(),
                AIStructuredOutputDefinition.builder()
                        .schemaId("image_context")
                        .version("v1")
                        .type(AIOutputType.JSON_OBJECT)
                        .field(AIOutputField.builder()
                                .name("context")
                                .type(AIOutputFieldType.STRING)
                                .required(true)
                                .maxLength(500)
                                .build())
                        .build());
    }
}
