package com.civichub.ai.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.ai.dto.AIRequest;
import com.civichub.ai.dto.AIResponse;
import com.civichub.ai.dto.AIUsage;
import com.civichub.ai.exception.AITimeoutException;
import com.civichub.ai.logging.AILogger;
import com.civichub.ai.model.AIProviderType;
import com.civichub.ai.ops.service.AIAuditService;
import com.civichub.ai.provider.AIProvider;
import com.civichub.ai.provider.AIProviderRegistry;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

class AIServiceImplTest {

    private final AIProviderRegistry registry = Mockito.mock(AIProviderRegistry.class);
    private final AILogger logger = Mockito.mock(AILogger.class);
    private final AIAuditService auditService = Mockito.mock(AIAuditService.class);
    private final AIProvider provider = Mockito.mock(AIProvider.class);
    private final AIServiceImpl service = new AIServiceImpl(registry, logger, auditService);

    @Test
    void routesRequestsThroughConfiguredProvider() {
        AIRequest request = AIRequest.builder()
                .input("sensitive user input")
                .correlationId("req-1")
                .build();
        AIResponse response = AIResponse.builder()
                .provider("LOCAL")
                .model("local")
                .usage(AIUsage.builder().totalTokens(12).build())
                .build();

        when(provider.type()).thenReturn(AIProviderType.LOCAL);
        when(provider.complete(request)).thenReturn(response);
        when(registry.activeProvider()).thenReturn(provider);

        AIResponse result = service.complete(request);

        assertThat(result).isSameAs(response);
        verify(provider).complete(request);
        verify(logger).success(eq("LOCAL"), anyLong(), eq(request), eq(response));
        verify(auditService).record(Mockito.argThat(record -> record.getStatus().name().equals("SUCCESS")));
    }

    @Test
    void logsProviderFailuresWithoutSwallowingThem() {
        AIRequest request = AIRequest.builder().input("sensitive user input").build();

        when(provider.type()).thenReturn(AIProviderType.LOCAL);
        when(provider.complete(request)).thenThrow(new AITimeoutException());
        when(registry.activeProvider()).thenReturn(provider);

        assertThatThrownBy(() -> service.complete(request)).isInstanceOf(AITimeoutException.class);
        verify(logger).failure(eq("LOCAL"), anyLong(), eq(request), eq("AI_TIMEOUT"));
        verify(auditService).record(Mockito.argThat(record -> record.getStatus().name().equals("FAILURE")
                && "AI_TIMEOUT".equals(record.getErrorCode())));
    }
}
