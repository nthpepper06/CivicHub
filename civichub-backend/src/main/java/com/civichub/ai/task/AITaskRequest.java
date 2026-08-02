package com.civichub.ai.task;

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
public class AITaskRequest {

    @Builder.Default
    private String requestId = UUID.randomUUID().toString();

    private AITaskType taskType;
    private String templateVersion;
    private String locale;
    private Long reportId;
    private Long citizenId;
    private String imageReference;

    @Builder.Default
    private Map<String, String> variables = new HashMap<>();

    @Builder.Default
    private Map<String, Object> metadata = new HashMap<>();
}
