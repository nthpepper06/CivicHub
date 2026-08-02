package com.civichub.ai.prompt;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.exception.PromptRenderingException;
import com.civichub.ai.exception.PromptTemplateDisabledException;
import com.civichub.ai.exception.PromptTemplateNotFoundException;
import com.civichub.ai.task.AITaskType;
import java.util.List;
import org.junit.jupiter.api.Test;

class CodeBackedPromptTemplateRegistryTest {

    @Test
    void resolvesActiveVersionDeterministically() {
        CodeBackedPromptTemplateRegistry registry = new CodeBackedPromptTemplateRegistry(List.of(
                template("REPORT_SUMMARY_V1", "v1", true),
                template("REPORT_SUMMARY_V2", "v2", true)));

        assertThat(registry.activeTemplate(AITaskType.REPORT_SUMMARY).getVersion()).isEqualTo("v2");
    }

    @Test
    void resolvesExplicitVersion() {
        PromptTemplate template = new CodeBackedPromptTemplateRegistry(List.of(
                        template("REPORT_SUMMARY_V1", "v1", true),
                        template("REPORT_SUMMARY_V2", "v2", true)))
                .template(AITaskType.REPORT_SUMMARY, "v1");

        assertThat(template.getTemplateId()).isEqualTo("REPORT_SUMMARY_V1");
    }

    @Test
    void rejectsMissingVersion() {
        assertThatThrownBy(() -> new CodeBackedPromptTemplateRegistry(List.of(template("REPORT_SUMMARY_V1", "v1", true)))
                        .template(AITaskType.REPORT_SUMMARY, "v9"))
                .isInstanceOf(PromptTemplateNotFoundException.class)
                .hasMessage("Prompt template was not found");
    }

    @Test
    void rejectsDisabledTemplate() {
        assertThatThrownBy(() -> new CodeBackedPromptTemplateRegistry(List.of(template("REPORT_SUMMARY_V1", "v1", false)))
                        .template(AITaskType.REPORT_SUMMARY, "v1"))
                .isInstanceOf(PromptTemplateDisabledException.class)
                .hasMessage("Prompt template is disabled");
    }

    @Test
    void rejectsDuplicateTaskVersion() {
        assertThatThrownBy(() -> new CodeBackedPromptTemplateRegistry(List.of(
                        template("A", "v1", true),
                        template("B", "v1", true))))
                .isInstanceOf(PromptRenderingException.class)
                .hasMessage("Duplicate prompt template registration");
    }

    private PromptTemplate template(String id, String version, boolean enabled) {
        return PromptTemplate.builder()
                .templateId(id)
                .taskType(AITaskType.REPORT_SUMMARY)
                .version(version)
                .enabled(enabled)
                .systemInstruction("System instruction")
                .userTemplate("Title: {{title}}")
                .requiredVariable("title")
                .outputSchemaId("plain_text")
                .outputSchemaVersion("v1")
                .build();
    }
}
