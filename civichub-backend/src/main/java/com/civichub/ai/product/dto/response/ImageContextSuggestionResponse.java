package com.civichub.ai.product.dto.response;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class ImageContextSuggestionResponse {

    private final String requestId;
    private final String suggestion;
    private final Double confidence;
    private final String provider;
    private final String model;
}
