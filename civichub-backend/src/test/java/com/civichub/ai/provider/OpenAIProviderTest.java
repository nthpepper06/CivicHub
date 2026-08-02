package com.civichub.ai.provider;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.exception.AIInvalidApiKeyException;
import com.civichub.ai.exception.AIQuotaExceededException;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.client.RestClient;

class OpenAIProviderTest {

    private HttpServer server;

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void sendsStructuredOutputRequestAndMapsResponse() throws Exception {
        AtomicReference<String> requestBody = new AtomicReference<>();
        AtomicReference<String> authorization = new AtomicReference<>();
        startServer(200, """
                {
                  "id": "chatcmpl-test",
                  "model": "gpt-test",
                  "choices": [
                    {
                      "message": {
                        "role": "assistant",
                        "content": "{\\"summary\\":\\"Streetlight outage reported.\\"}"
                      }
                    }
                  ],
                  "usage": {
                    "prompt_tokens": 10,
                    "completion_tokens": 4,
                    "total_tokens": 14
                  }
                }
                """, requestBody, authorization);
        OpenAIProvider provider = new OpenAIProvider(properties(), RestClient.builder());

        AIResponse response = provider.complete(request());

        assertThat(authorization).hasValue("Bearer test-key");
        assertThat(requestBody.get()).contains("\"response_format\"");
        assertThat(requestBody.get()).contains("\"json_schema\"");
        assertThat(response.getProvider()).isEqualTo("OPENAI");
        assertThat(response.getModel()).isEqualTo("gpt-test");
        assertThat(response.getOutput()).contains("Streetlight outage");
        assertThat(response.getUsage().getInputTokens()).isEqualTo(10);
        assertThat(response.getUsage().getOutputTokens()).isEqualTo(4);
        assertThat(response.getMetadata()).containsEntry("outputSchemaType", "JSON_OBJECT");
    }

    @Test
    void missingApiKeyFailsSafelyBeforeHttpCall() {
        AIProperties properties = properties();
        properties.setApiKey("");

        assertThatThrownBy(() -> new OpenAIProvider(properties, RestClient.builder()).complete(request()))
                .isInstanceOf(AIInvalidApiKeyException.class)
                .hasMessage("AI provider authentication failed");
    }

    @Test
    void quotaResponseMapsToAIException() throws Exception {
        startServer(429, "{\"error\":{\"message\":\"quota\"}}", new AtomicReference<>(), new AtomicReference<>());
        OpenAIProvider provider = new OpenAIProvider(properties(), RestClient.builder());

        assertThatThrownBy(() -> provider.complete(request())).isInstanceOf(AIQuotaExceededException.class);
    }

    @Test
    void transientProviderFailureIsRetriedBeforeSuccess() throws Exception {
        AtomicInteger attempts = new AtomicInteger();
        AtomicReference<String> requestBody = new AtomicReference<>();
        AtomicReference<String> authorization = new AtomicReference<>();
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/chat/completions", exchange -> {
            int attempt = attempts.incrementAndGet();
            if (attempt == 1) {
                handle(exchange, 503, "{\"error\":{\"message\":\"temporary\"}}", requestBody, authorization);
                return;
            }
            handle(exchange, 200, """
                    {
                      "id": "chatcmpl-test",
                      "model": "gpt-test",
                      "choices": [
                        {
                          "message": {
                            "role": "assistant",
                            "content": "{\\"summary\\":\\"Recovered after retry.\\"}"
                          }
                        }
                      ]
                    }
                    """, requestBody, authorization);
        });
        server.start();
        AIProperties properties = properties();
        properties.setRetryMaxAttempts(2);
        properties.setRetryBackoff(Duration.ofMillis(1));
        OpenAIProvider provider = new OpenAIProvider(properties, RestClient.builder());

        AIResponse response = provider.complete(request());

        assertThat(attempts).hasValue(2);
        assertThat(response.getOutput()).contains("Recovered after retry");
    }

    private void startServer(
            int status,
            String response,
            AtomicReference<String> requestBody,
            AtomicReference<String> authorization) throws IOException {
        server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
        server.createContext("/v1/chat/completions", exchange -> handle(exchange, status, response, requestBody, authorization));
        server.start();
    }

    private void handle(
            HttpExchange exchange,
            int status,
            String response,
            AtomicReference<String> requestBody,
            AtomicReference<String> authorization) throws IOException {
        authorization.set(exchange.getRequestHeaders().getFirst("Authorization"));
        requestBody.set(new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8));
        byte[] bytes = response.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(status, bytes.length);
        exchange.getResponseBody().write(bytes);
        exchange.close();
    }

    private AIProperties properties() {
        AIProperties properties = new AIProperties();
        properties.setApiKey("test-key");
        int port = server == null ? 1 : server.getAddress().getPort();
        properties.setBaseUrl("http://127.0.0.1:%d/v1".formatted(port));
        properties.setModel("gpt-test");
        properties.setTimeout(Duration.ofSeconds(5));
        return properties;
    }

    private AIRequest request() {
        return AIRequest.builder()
                .input("input")
                .systemContent("System")
                .userContent("User")
                .correlationId("req-1")
                .taskType("REPORT_SUMMARY")
                .templateId("REPORT_SUMMARY_V1")
                .templateVersion("v1")
                .outputSchemaId("report_summary")
                .outputSchemaVersion("v1")
                .model("gpt-test")
                .temperature(0.2)
                .maxTokens(128)
                .metadata(Map.of(
                        "outputSchemaType", "JSON_OBJECT",
                        "jsonSchema", Map.of(
                                "type", "object",
                                "properties", Map.of("summary", Map.of("type", "string")),
                                "required", java.util.List.of("summary"),
                                "additionalProperties", false)))
                .build();
    }
}
