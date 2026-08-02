package com.civichub.ai.task;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.exception.AITaskDisabledException;
import com.civichub.ai.exception.PromptRenderingException;
import com.civichub.ai.exception.UnsupportedAITaskException;
import java.util.List;
import org.junit.jupiter.api.Test;

class CodeBackedAITaskRegistryTest {

    @Test
    void resolvesKnownEnabledTask() {
        AITaskDefinition definition = new CodeBackedAITaskRegistry().resolve(AITaskType.REPORT_SUMMARY);

        assertThat(definition.getType()).isEqualTo(AITaskType.REPORT_SUMMARY);
        assertThat(definition.getInputType()).isEqualTo(AITaskInputType.TEXT);
        assertThat(definition.getRequiredVariables()).containsExactlyInAnyOrder("title", "description");
    }

    @Test
    void rejectsUnknownTask() {
        assertThatThrownBy(() -> new CodeBackedAITaskRegistry().resolve(null))
                .isInstanceOf(UnsupportedAITaskException.class)
                .hasMessage("Unsupported AI task");
    }

    @Test
    void rejectsDisabledReservedTask() {
        assertThatThrownBy(() -> new CodeBackedAITaskRegistry().resolve(AITaskType.IMAGE_OCR))
                .isInstanceOf(AITaskDisabledException.class)
                .hasMessage("AI task is disabled");
    }

    @Test
    void rejectsDuplicateTaskRegistration() {
        AITaskDefinition first = AITaskDefinition.builder()
                .type(AITaskType.REPORT_SUMMARY)
                .inputType(AITaskInputType.TEXT)
                .build();
        AITaskDefinition second = AITaskDefinition.builder()
                .type(AITaskType.REPORT_SUMMARY)
                .inputType(AITaskInputType.TEXT)
                .build();

        assertThatThrownBy(() -> new CodeBackedAITaskRegistry(List.of(first, second)))
                .isInstanceOf(PromptRenderingException.class)
                .hasMessage("Duplicate AI task registration");
    }
}
