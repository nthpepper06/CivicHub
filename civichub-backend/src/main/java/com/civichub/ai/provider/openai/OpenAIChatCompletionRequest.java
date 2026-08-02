package com.civichub.ai.provider.openai;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;
import java.util.Map;
import lombok.Builder;

@Builder
@JsonInclude(JsonInclude.Include.NON_NULL)
public record OpenAIChatCompletionRequest(
        String model,
        List<Message> messages,
        Double temperature,
        @JsonProperty("max_tokens") Integer maxTokens,
        @JsonProperty("response_format") Map<String, Object> responseFormat) {

    @Builder
    public record Message(String role, String content) {}
}
