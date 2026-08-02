package com.civichub.ai.output;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.StructuredOutputDefinitionException;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.Map;
import org.junit.jupiter.api.Test;

class DefaultAIOutputMapperTest {

    private final DefaultAIOutputMapper mapper = new DefaultAIOutputMapper(new ObjectMapper());
    private final AIStructuredOutputDefinition schema = new CodeBackedAIOutputSchemaRegistry()
            .resolve("report_summary", "v1");

    @Test
    void mapsValidJsonObject() {
        Map<String, Object> mapped = mapper.mapJsonObject(
                AIResponse.builder().output("{\"summary\":\"Streetlight outage reported.\"}").build(),
                schema);

        assertThat(mapped).containsEntry("summary", "Streetlight outage reported.");
    }

    @Test
    void rejectsMissingRequiredField() {
        assertThatThrownBy(() -> mapper.mapJsonObject(AIResponse.builder().output("{}").build(), schema))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("AI provider output is missing a required field");
    }

    @Test
    void rejectsUnknownField() {
        assertThatThrownBy(() -> mapper.mapJsonObject(
                        AIResponse.builder().output("{\"summary\":\"ok\",\"extra\":\"nope\"}").build(),
                        schema))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("AI provider returned unknown structured output field");
    }

    @Test
    void rejectsInvalidFieldType() {
        assertThatThrownBy(() -> mapper.mapJsonObject(
                        AIResponse.builder().output("{\"summary\":123}").build(),
                        schema))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("AI provider output field has an invalid type");
    }

    @Test
    void rejectsInvalidJson() {
        assertThatThrownBy(() -> mapper.mapJsonObject(
                        AIResponse.builder().output("not-json").build(),
                        schema))
                .isInstanceOf(StructuredOutputDefinitionException.class)
                .hasMessage("AI provider returned invalid JSON output");
    }
}
