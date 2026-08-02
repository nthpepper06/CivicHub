package com.civichub.ai.prompt;

import com.civichub.ai.exception.PromptRenderingException;
import com.civichub.ai.exception.PromptVariableMissingException;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class SafePromptRenderer implements PromptRenderer {

    private static final Pattern PLACEHOLDER = Pattern.compile("\\{\\{([a-zA-Z0-9_]+)}}");
    private static final int MAX_VARIABLE_LENGTH = 4_000;
    private static final int MAX_RENDERED_LENGTH = 12_000;

    @Override
    public RenderedPrompt render(PromptTemplate template, Map<String, String> variables) {
        if (PLACEHOLDER.matcher(template.getSystemInstruction()).find()) {
            throw new PromptRenderingException("System instruction cannot contain variables");
        }
        Map<String, String> safeVariables = variables == null ? Map.of() : variables;
        validateRequired(template, safeVariables);
        String userContent = renderUserTemplate(template, safeVariables);
        if (PLACEHOLDER.matcher(userContent).find()) {
            throw new PromptRenderingException("Prompt contains unresolved placeholders");
        }
        String systemContent = normalizeWhitespace(template.getSystemInstruction());
        userContent = normalizeWhitespace(userContent);
        if (systemContent.length() + userContent.length() > MAX_RENDERED_LENGTH) {
            throw new PromptRenderingException("Rendered prompt exceeds maximum length");
        }
        return RenderedPrompt.builder()
                .systemContent(systemContent)
                .userContent(userContent)
                .build();
    }

    private void validateRequired(PromptTemplate template, Map<String, String> variables) {
        for (String required : template.getRequiredVariables()) {
            if (!StringUtils.hasText(variables.get(required))) {
                throw new PromptVariableMissingException(required);
            }
            if (variables.get(required).length() > MAX_VARIABLE_LENGTH) {
                throw new PromptRenderingException("Prompt variable exceeds maximum length");
            }
        }
    }

    private String renderUserTemplate(PromptTemplate template, Map<String, String> variables) {
        Matcher matcher = PLACEHOLDER.matcher(template.getUserTemplate());
        StringBuffer rendered = new StringBuffer();
        Set<String> seen = new HashSet<>();
        while (matcher.find()) {
            String name = matcher.group(1);
            seen.add(name);
            boolean declared = template.getRequiredVariables().contains(name) || template.getOptionalVariables().contains(name);
            if (!declared) {
                throw new PromptRenderingException("Prompt references undeclared variable");
            }
            String value = variables.get(name);
            if (!StringUtils.hasText(value)) {
                if (template.getRequiredVariables().contains(name)) {
                    throw new PromptVariableMissingException(name);
                }
                value = "";
            }
            if (value.length() > MAX_VARIABLE_LENGTH) {
                throw new PromptRenderingException("Prompt variable exceeds maximum length");
            }
            matcher.appendReplacement(rendered, Matcher.quoteReplacement(delimitUntrusted(name, value)));
        }
        matcher.appendTail(rendered);
        for (String required : template.getRequiredVariables()) {
            if (!seen.contains(required)) {
                throw new PromptRenderingException("Required prompt variable is not used by template");
            }
        }
        return rendered.toString();
    }

    private String delimitUntrusted(String name, String value) {
        String escaped = value.replace("</untrusted>", "<\\/untrusted>");
        return "<untrusted name=\"%s\">\n%s\n</untrusted>".formatted(name, escaped);
    }

    private String normalizeWhitespace(String value) {
        return value.replace("\r\n", "\n")
                .replaceAll("[ \\t]+", " ")
                .replaceAll("\\n{3,}", "\n\n")
                .trim();
    }
}
