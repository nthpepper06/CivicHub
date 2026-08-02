package com.civichub.ai.provider;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIInvalidApiKeyException;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.exception.AIQuotaExceededException;
import com.civichub.ai.exception.AITimeoutException;
import com.civichub.ai.exception.PipelineExecutionException;
import com.civichub.ai.model.AIProviderType;
import com.civichub.ai.provider.openai.OpenAIChatCompletionRequest;
import com.civichub.ai.provider.openai.OpenAIChatCompletionResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Component
@RequiredArgsConstructor
public class OpenAIProvider implements AIProvider {

    private final AIProperties properties;
    private final RestClient.Builder restClientBuilder;

    @Override
    public AIProviderType type() {
        return AIProviderType.OPENAI;
    }

    @Override
    public AIResponse complete(AIRequest request) {
        if (!StringUtils.hasText(properties.getApiKey())) {
            throw new AIInvalidApiKeyException();
        }
        RuntimeException lastFailure = null;
        int attempts = Math.max(1, properties.getRetryMaxAttempts());
        for (int attempt = 1; attempt <= attempts; attempt++) {
            try {
                return completeOnce(request);
            } catch (AITimeoutException | AIProviderUnavailableException exception) {
                lastFailure = exception;
                if (attempt == attempts) {
                    throw exception;
                }
                backoff();
            }
        }
        throw lastFailure == null ? new AIProviderUnavailableException(type().name()) : lastFailure;
    }

    private AIResponse completeOnce(AIRequest request) {
        try {
            OpenAIChatCompletionResponse response = restClient().post()
                    .uri("/chat/completions")
                    .contentType(MediaType.APPLICATION_JSON)
                    .headers(headers -> headers.setBearerAuth(properties.getApiKey()))
                    .body(toOpenAIRequest(request))
                    .retrieve()
                    .onStatus(HttpStatusCode::isError, (httpRequest, clientResponse) -> {
                        throw mapStatus(clientResponse.getStatusCode());
                    })
                    .body(OpenAIChatCompletionResponse.class);
            return toAIResponse(response, request);
        } catch (ResourceAccessException exception) {
            throw new AITimeoutException();
        } catch (RestClientResponseException exception) {
            throw mapStatus(exception.getStatusCode());
        }
    }

    private void backoff() {
        try {
            Thread.sleep(properties.getRetryBackoff().toMillis());
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new AIProviderUnavailableException(type().name());
        }
    }

    private RestClient restClient() {
        Duration timeout = properties.getTimeout();
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(timeout);
        requestFactory.setReadTimeout(timeout);
        return restClientBuilder
                .baseUrl(properties.getBaseUrl())
                .requestFactory(requestFactory)
                .build();
    }

    private OpenAIChatCompletionRequest toOpenAIRequest(AIRequest request) {
        return OpenAIChatCompletionRequest.builder()
                .model(StringUtils.hasText(request.getModel()) ? request.getModel() : properties.getModel())
                .temperature(request.getTemperature())
                .maxTokens(request.getMaxTokens())
                .messages(List.of(
                        OpenAIChatCompletionRequest.Message.builder()
                                .role("system")
                                .content(request.getSystemContent())
                                .build(),
                        OpenAIChatCompletionRequest.Message.builder()
                                .role("user")
                                .content(request.getUserContent())
                                .build()))
                .responseFormat(responseFormat(request))
                .build();
    }

    private Map<String, Object> responseFormat(AIRequest request) {
        Object schema = request.getMetadata().get("jsonSchema");
        String outputType = String.valueOf(request.getMetadata().getOrDefault("outputSchemaType", ""));
        if (!"JSON_OBJECT".equals(outputType) || schema == null) {
            return null;
        }
        return Map.of(
                "type", "json_schema",
                "json_schema", Map.of(
                        "name", request.getOutputSchemaId(),
                        "strict", true,
                        "schema", schema));
    }

    private AIResponse toAIResponse(OpenAIChatCompletionResponse response, AIRequest request) {
        if (response == null || response.choices() == null || response.choices().isEmpty()) {
            throw new PipelineExecutionException("AI provider returned an empty response");
        }
        OpenAIChatCompletionResponse.Choice choice = response.choices().getFirst();
        String output = choice.message() == null ? null : choice.message().content();
        return AIResponse.builder()
                .output(output)
                .provider(type().name())
                .model(response.model())
                .usage(response.usage() == null
                        ? null
                        : com.civichub.ai.dto.AIUsage.builder()
                                .inputTokens(response.usage().promptTokens())
                                .outputTokens(response.usage().completionTokens())
                                .totalTokens(response.usage().totalTokens())
                                .build())
                .metadata(new java.util.HashMap<>(request.getMetadata()))
                .build();
    }

    private RuntimeException mapStatus(HttpStatusCode status) {
        if (status.value() == 401 || status.value() == 403) {
            return new AIInvalidApiKeyException();
        }
        if (status.value() == 429) {
            return new AIQuotaExceededException();
        }
        if (status.value() == 408 || status.value() == 504) {
            return new AITimeoutException();
        }
        return new AIProviderUnavailableException(type().name());
    }
}
