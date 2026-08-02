package com.civichub.ai.task;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.exception.AITaskDisabledException;
import com.civichub.ai.exception.PromptRenderingException;
import com.civichub.ai.exception.PromptVariableMissingException;
import com.civichub.ai.output.CodeBackedAIOutputSchemaRegistry;
import com.civichub.ai.prompt.CodeBackedPromptTemplateRegistry;
import com.civichub.ai.prompt.SafePromptRenderer;
import java.util.Map;
import org.junit.jupiter.api.Test;

class DefaultAIRequestFactoryTest {

    @Test
    void propagatesTaskTemplateLocaleCorrelationAndSchemaMetadata() {
        DefaultAIRequestFactory factory = factory(new AIProperties());

        AIRequest request = factory.create(AITaskRequest.builder()
                .requestId("req-1")
                .taskType(AITaskType.REPORT_SUMMARY)
                .locale("en-US")
                .reportId(10L)
                .citizenId(20L)
                .variables(Map.of(
                        "title", "Broken streetlight",
                        "description", "Lamp is out"))
                .build());

        assertThat(request.getCorrelationId()).isEqualTo("req-1");
        assertThat(request.getTaskType()).isEqualTo("REPORT_SUMMARY");
        assertThat(request.getTemplateId()).isEqualTo("REPORT_SUMMARY_V1");
        assertThat(request.getTemplateVersion()).isEqualTo("v1");
        assertThat(request.getOutputSchemaId()).isEqualTo("report_summary");
        assertThat(request.getOutputSchemaVersion()).isEqualTo("v1");
        assertThat(request.getLocale()).isEqualTo("en-US");
        assertThat(request.getSystemContent()).contains("untrusted data");
        assertThat(request.getUserContent()).contains("<untrusted name=\"description\">");
        assertThat(request.getMetadata()).containsEntry("reportId", 10L);
        assertThat(request.getMetadata()).containsEntry("citizenId", 20L);
        assertThat(request.getMetadata()).containsEntry("taskInputType", "TEXT");
        assertThat(request.getMetadata()).containsEntry("templateId", "REPORT_SUMMARY_V1");
        assertThat(request.getMetadata()).containsEntry("outputSchemaId", "report_summary");
    }

    @Test
    void appliesGlobalDefaultsAndTaskSpecificOverrides() {
        AIProperties properties = new AIProperties();
        properties.setModel("global-model");
        properties.setTemperature(0.2);
        properties.setMaxTokens(1024);
        AIProperties.TaskProperties task = new AIProperties.TaskProperties();
        task.setModel("task-model");
        task.setTemperature(0.1);
        task.setMaxTokens(128);
        task.setTemplateVersion("v1");
        properties.setTasks(Map.of("REPORT_SUMMARY", task));

        AIRequest request = factory(properties).create(AITaskRequest.builder()
                .requestId("req-2")
                .taskType(AITaskType.REPORT_SUMMARY)
                .variables(Map.of("title", "Title", "description", "Description"))
                .build());

        assertThat(request.getModel()).isEqualTo("task-model");
        assertThat(request.getTemperature()).isEqualTo(0.1);
        assertThat(request.getMaxTokens()).isEqualTo(128);
    }

    @Test
    void disabledTaskConfigFailsBeforeRendering() {
        AIProperties properties = new AIProperties();
        AIProperties.TaskProperties task = new AIProperties.TaskProperties();
        task.setEnabled(false);
        properties.setTasks(Map.of("REPORT_SUMMARY", task));

        assertThatThrownBy(() -> factory(properties).create(AITaskRequest.builder()
                        .taskType(AITaskType.REPORT_SUMMARY)
                        .variables(Map.of("title", "Title", "description", "Description"))
                        .build()))
                .isInstanceOf(AITaskDisabledException.class);
    }

    @Test
    void renderingFailureNeverProducesProviderRequest() {
        assertThatThrownBy(() -> factory(new AIProperties()).create(AITaskRequest.builder()
                        .taskType(AITaskType.REPORT_SUMMARY)
                        .variables(Map.of("title", "Title"))
                        .build()))
                .isInstanceOf(PromptVariableMissingException.class);
    }

    @Test
    void invalidTaskConfigFailsSafely() {
        AIProperties properties = new AIProperties();
        AIProperties.TaskProperties task = new AIProperties.TaskProperties();
        task.setTemperature(9.9);
        properties.setTasks(Map.of("REPORT_SUMMARY", task));

        assertThatThrownBy(() -> factory(properties).create(AITaskRequest.builder()
                        .taskType(AITaskType.REPORT_SUMMARY)
                        .variables(Map.of("title", "Title", "description", "Description"))
                        .build()))
                .isInstanceOf(PromptRenderingException.class)
                .hasMessage("Invalid AI task temperature");
    }

    private DefaultAIRequestFactory factory(AIProperties properties) {
        return new DefaultAIRequestFactory(
                new CodeBackedAITaskRegistry(),
                new CodeBackedPromptTemplateRegistry(),
                new SafePromptRenderer(),
                new CodeBackedAIOutputSchemaRegistry(),
                properties);
    }
}
