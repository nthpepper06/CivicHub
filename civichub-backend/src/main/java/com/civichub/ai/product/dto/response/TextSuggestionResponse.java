package com.civichub.ai.product.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class TextSuggestionResponse {

    private final String requestId;
    private final String suggestion;
    private final String provider;
    private final String model;
}
