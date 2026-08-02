package com.civichub.ai.output;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.exception.StructuredOutputDefinitionException;
import java.util.List;
import org.junit.jupiter.api.Test;

class CodeBackedAIOutputSchemaRegistryTest {

    @Test
    void resolvesPlainTextDefinition() {
        AIStructuredOutputDefinition definition = new CodeBackedAIOutputSchemaRegistry()
                .resolve("plain_text", "v1");

        assertThat(definition.getType()).isEqualTo(AIOutputType.PLAIN_TEXT);
        assertThat(definition.getFields()).isEmpty();
    }

    @Test
    void resolvesJsonObjectDefinition() {
        AIStructuredOutputDefinition definition = new CodeBackedAIOutputSchemaRegistry()
                .resolve("report_summary", "v1");

        assertThat(definition.getType()).isEqualTo(AIOutputType.JSON_OBJECT);
        assertThat(definition.getFields()).extracting(AIOutputField::getName).containsExactly("summary");
        assertThat(definition.getFields().getFirst().isRequired()).isTrue();
    }

    @Test
    void rejectsDuplicateSchemaVersion() {
        AIStructuredOutputDefinition one = schema("schema", "v1");
        AIStructuredOutputDefinition two = schema("schema", "v1");

        assertThatThrownBy(() -> new CodeBackedAIOutputSchemaRegistry(List.of(one, two)))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("Duplicate structured output schema");
    }

    @Test
    void rejectsInvalidRequiredFieldName() {
        AIStructuredOutputDefinition invalid = AIStructuredOutputDefinition.builder()
                .schemaId("schema")
                .version("v1")
                .type(AIOutputType.JSON_OBJECT)
                .field(AIOutputField.builder()
                        .name(" ")
                        .type(AIOutputFieldType.STRING)
                        .required(true)
                        .build())
                .build();

        assertThatThrownBy(() -> new CodeBackedAIOutputSchemaRegistry(List.of(invalid)))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("Structured output field requires a name");
    }

    @Test
    void rejectsEnumConstraintForNonStringField() {
        AIStructuredOutputDefinition invalid = AIStructuredOutputDefinition.builder()
                .schemaId("schema")
                .version("v1")
                .type(AIOutputType.JSON_OBJECT)
                .field(AIOutputField.builder()
                        .name("score")
                        .type(AIOutputFieldType.INTEGER)
                        .enumValue("HIGH")
                        .build())
                .build();

        assertThatThrownBy(() -> new CodeBackedAIOutputSchemaRegistry(List.of(invalid)))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("Enum constraints are only supported for string fields");
    }

    private AIStructuredOutputDefinition schema(String id, String version) {
        return AIStructuredOutputDefinition.builder()
                .schemaId(id)
                .version(version)
                .type(AIOutputType.PLAIN_TEXT)
                .build();
    }
}
