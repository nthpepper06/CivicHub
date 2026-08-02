package com.civichub.ai.pipeline.context;

import com.civichub.ai.dto.AIError;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AIProcessingResult<T> {

    private boolean success;
    private long processingTimeMs;
    private String provider;
    private T payload;

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();

    @Builder.Default
    private List<AIError> errors = List.of();
}
