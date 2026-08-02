package com.civichub.ai.dto;

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
public class AIUsage {

    private Integer inputTokens;
    private Integer outputTokens;
    private Integer totalTokens;
}
