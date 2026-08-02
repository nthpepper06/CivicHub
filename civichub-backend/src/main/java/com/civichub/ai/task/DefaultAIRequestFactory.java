package com.civichub.ai.task;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.exception.AITaskDisabledException;
import com.civichub.ai.output.AIOutputField;
import com.civichub.ai.output.AIStructuredOutputDefinition;
import com.civichub.ai.output.AIOutputSchemaRegistry;
import com.civichub.ai.prompt.PromptRenderer;
import com.civichub.ai.prompt.PromptTemplate;
import com.civichub.ai.prompt.PromptTemplateRegistry;
import com.civichub.ai.prompt.RenderedPrompt;
import java.util.HashMap;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
@RequiredArgsConstructor
public class DefaultAIRequestFactory implements AIRequestFactory {

    private final AITaskRegistry taskRegistry;
    private final PromptTemplateRegistry templateRegistry;
    private final PromptRenderer promptRenderer;
    private final AIOutputSchemaRegistry outputSchemaRegistry;
    private final AIProperties aiProperties;

    @Override
    public AIRequest create(AITaskRequest request) {
        AITaskDefinition task = taskRegistry.resolve(request.getTaskType());
        AIProperties.TaskProperties taskProperties = taskProperties(request.getTaskType());
        if (Boolean.FALSE.equals(taskProperties.getEnabled())) {
            throw new AITaskDisabledException(request.getTaskType().name());
        }
        String version = StringUtils.hasText(request.getTemplateVersion())
                ? request.getTemplateVersion()
                : taskProperties.getTemplateVersion();
        PromptTemplate template = templateRegistry.template(request.getTaskType(), version);
        RenderedPrompt renderedPrompt = promptRenderer.render(template, request.getVariables());
        AIStructuredOutputDefinition outputDefinition = outputSchemaRegistry.resolve(
                template.getOutputSchemaId(),
                template.getOutputSchemaVersion());
        Map<String, Object> metadata = new HashMap<>();
        if (request.getMetadata() != null) {
            metadata.putAll(request.getMetadata());
        }
        metadata.put("taskInputType", task.getInputType().name());
        metadata.put("taskType", request.getTaskType().name());
        metadata.put("templateId", template.getTemplateId());
        metadata.put("templateVersion", template.getVersion());
        metadata.put("outputSchemaId", outputDefinition.getSchemaId());
        metadata.put("outputSchemaVersion", outputDefinition.getVersion());
        metadata.put("outputSchemaType", outputDefinition.getType().name());
        metadata.put("jsonSchema", jsonSchema(outputDefinition));
        metadata.put("outputFields", outputDefinition.getFields().stream()
                .map(AIOutputField::getName)
                .toList());
        if (request.getReportId() != null) {
            metadata.put("reportId", request.getReportId());
        }
        if (request.getCitizenId() != null) {
            metadata.put("citizenId", request.getCitizenId());
        }
        return AIRequest.builder()
                .input(renderedPrompt.combinedInput())
                .systemContent(renderedPrompt.getSystemContent())
                .userContent(renderedPrompt.getUserContent())
                .correlationId(request.getRequestId())
                .taskType(request.getTaskType().name())
                .templateId(template.getTemplateId())
                .templateVersion(template.getVersion())
                .outputSchemaId(outputDefinition.getSchemaId())
                .outputSchemaVersion(outputDefinition.getVersion())
                .locale(StringUtils.hasText(request.getLocale()) ? request.getLocale() : "vi-VN")
                .model(StringUtils.hasText(taskProperties.getModel()) ? taskProperties.getModel() : aiProperties.getModel())
                .temperature(taskProperties.getTemperature() != null
                        ? taskProperties.getTemperature()
                        : aiProperties.getTemperature())
                .maxTokens(taskProperties.getMaxTokens() != null ? taskProperties.getMaxTokens() : aiProperties.getMaxTokens())
                .metadata(metadata)
                .build();
    }

    private AIProperties.TaskProperties taskProperties(AITaskType taskType) {
        AIProperties.TaskProperties properties = aiProperties.getTasks().get(taskType.name());
        if (properties == null) {
            properties = aiProperties.getTasks().get(taskType.name().toLowerCase(java.util.Locale.ROOT));
        }
        properties = properties == null ? new AIProperties.TaskProperties() : properties;
        validateTaskProperties(properties);
        return properties;
    }

    private void validateTaskProperties(AIProperties.TaskProperties properties) {
        if (properties.getTemperature() != null
                && (properties.getTemperature() < 0.0 || properties.getTemperature() > 2.0)) {
            throw new com.civichub.ai.exception.PromptRenderingException("Invalid AI task temperature");
        }
        if (properties.getMaxTokens() != null && properties.getMaxTokens() <= 0) {
            throw new com.civichub.ai.exception.PromptRenderingException("Invalid AI task max tokens");
        }
        if (properties.getTemplateVersion() != null && !StringUtils.hasText(properties.getTemplateVersion())) {
            throw new com.civichub.ai.exception.PromptRenderingException("Invalid AI task template version");
        }
    }

    private Map<String, Object> jsonSchema(AIStructuredOutputDefinition definition) {
        if (definition.getType() == com.civichub.ai.output.AIOutputType.PLAIN_TEXT) {
            return Map.of("type", "string");
        }
        Map<String, Object> properties = new java.util.LinkedHashMap<>();
        java.util.List<String> required = new java.util.ArrayList<>();
        for (AIOutputField field : definition.getFields()) {
            Map<String, Object> fieldSchema = new java.util.LinkedHashMap<>();
            fieldSchema.put("type", jsonType(field.getType()));
            if (field.getMaxLength() != null) {
                fieldSchema.put("maxLength", field.getMaxLength());
            }
            if (field.getEnumValues() != null && !field.getEnumValues().isEmpty()) {
                fieldSchema.put("enum", field.getEnumValues());
            }
            properties.put(field.getName(), fieldSchema);
            if (field.isRequired()) {
                required.add(field.getName());
            }
        }
        return Map.of(
                "type", "object",
                "properties", properties,
                "required", required,
                "additionalProperties", false);
    }

    private String jsonType(com.civichub.ai.output.AIOutputFieldType type) {
        return switch (type) {
            case STRING -> "string";
            case INTEGER -> "integer";
            case NUMBER -> "number";
            case BOOLEAN -> "boolean";
            case ARRAY -> "array";
            case OBJECT -> "object";
        };
    }
}
