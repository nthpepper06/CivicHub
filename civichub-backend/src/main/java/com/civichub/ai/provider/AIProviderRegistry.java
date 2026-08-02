package com.civichub.ai.provider;

import com.civichub.ai.config.AIProperties;
import com.civichub.ai.exception.AIProviderUnavailableException;
import com.civichub.ai.exception.UnsupportedAIProviderException;
import com.civichub.ai.model.AIProviderType;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class AIProviderRegistry {

    private final AIProperties properties;
    private final List<AIProvider> providers;

    public AIProvider activeProvider() {
        AIProviderType activeType = AIProviderType.from(properties.getProvider())
                .orElseThrow(() -> new UnsupportedAIProviderException(properties.getProvider()));
        AIProvider provider = providersByType().get(activeType);
        if (provider == null) {
            throw new AIProviderUnavailableException(activeType.name());
        }
        return provider;
    }

    public List<AIProviderType> availableProviderTypes() {
        return List.copyOf(providersByType().keySet());
    }

    private Map<AIProviderType, AIProvider> providersByType() {
        Map<AIProviderType, AIProvider> mapped = new EnumMap<>(AIProviderType.class);
        for (AIProvider provider : providers) {
            mapped.put(provider.type(), provider);
        }
        return mapped;
    }
}
