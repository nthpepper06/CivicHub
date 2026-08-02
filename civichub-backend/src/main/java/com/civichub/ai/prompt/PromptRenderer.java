package com.civichub.ai.prompt;

import java.util.Map;

public interface PromptRenderer {

    RenderedPrompt render(PromptTemplate template, Map<String, String> variables);
}
