package com.civichub.ai.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ReportSummaryAIRequest {

    @NotBlank
    @Size(max = 200)
    private String title;

    @NotBlank
    @Size(max = 4000)
    private String description;

    @Size(max = 20)
    private String locale;

    private Long reportId;
}
