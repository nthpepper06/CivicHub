package com.civichub.ai.pipeline.context;

import com.civichub.ai.dto.AIRequest;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
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
public class AIProcessingRequest {

    @Builder.Default
    private String requestId = UUID.randomUUID().toString();

    private String imageReference;
    private Long reportId;
    private Long citizenId;
    private String locale;
    private String traceId;
    private AIRequest providerRequest;

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
}
