package com.civichub.ai.task;

import com.civichub.ai.exception.AITaskDisabledException;
import com.civichub.ai.exception.PromptRenderingException;
import com.civichub.ai.exception.UnsupportedAITaskException;
import java.util.Collection;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Component;

@Component
public class CodeBackedAITaskRegistry implements AITaskRegistry {

    private final Map<AITaskType, AITaskDefinition> definitions;

    public CodeBackedAITaskRegistry() {
        this(defaultDefinitions());
    }

    public CodeBackedAITaskRegistry(Collection<AITaskDefinition> definitions) {
        Map<AITaskType, AITaskDefinition> mapped = new EnumMap<>(AITaskType.class);
        for (AITaskDefinition definition : definitions) {
            if (mapped.putIfAbsent(definition.getType(), definition) != null) {
                throw new PromptRenderingException("Duplicate AI task registration");
            }
        }
        this.definitions = Map.copyOf(mapped);
    }

    @Override
    public AITaskDefinition resolve(AITaskType taskType) {
        if (taskType == null || !definitions.containsKey(taskType)) {
            throw new UnsupportedAITaskException(String.valueOf(taskType));
        }
        AITaskDefinition definition = definitions.get(taskType);
        if (!definition.isEnabled()) {
            throw new AITaskDisabledException(taskType.name());
        }
        return definition;
    }

    private static List<AITaskDefinition> defaultDefinitions() {
        return List.of(
                AITaskDefinition.builder()
                        .type(AITaskType.REPORT_SUMMARY)
                        .inputType(AITaskInputType.TEXT)
                        .requiredVariable("title")
                        .requiredVariable("description")
                        .build(),
                AITaskDefinition.builder()
                        .type(AITaskType.IMAGE_CONTEXT)
                        .inputType(AITaskInputType.IMAGE)
                        .requiredVariable("title")
                        .optionalVariable("location")
                        .build(),
                reserved(AITaskType.REPORT_DESCRIPTION_ENHANCEMENT, AITaskInputType.TEXT),
                reserved(AITaskType.REPORT_CATEGORY_CLASSIFICATION, AITaskInputType.TEXT),
                reserved(AITaskType.DEPARTMENT_RECOMMENDATION, AITaskInputType.TEXT),
                reserved(AITaskType.DUPLICATE_REPORT_ANALYSIS, AITaskInputType.TEXT),
                reserved(AITaskType.IMAGE_OCR, AITaskInputType.IMAGE),
                reserved(AITaskType.RESOLUTION_EVIDENCE_ANALYSIS, AITaskInputType.IMAGE),
                reserved(AITaskType.SPATIAL_INSIGHT, AITaskInputType.TEXT));
    }

    private static AITaskDefinition reserved(AITaskType type, AITaskInputType inputType) {
        return AITaskDefinition.builder()
                .type(type)
                .inputType(inputType)
                .enabled(false)
                .build();
    }
}
