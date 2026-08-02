package com.civichub.ai.product.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ImageContextSuggestionRequest {

    @NotBlank
    @Size(max = 200)
    private String title;

    @Size(max = 500)
    private String location;

    @NotBlank
    @Size(max = 2000)
    private String imageUrl;

    @Size(max = 20)
    private String locale;

    private Long reportId;
}
