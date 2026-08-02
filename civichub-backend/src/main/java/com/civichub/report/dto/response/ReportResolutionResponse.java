package com.civichub.report.dto.response;

import java.time.LocalDateTime;
import java.util.List;
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
public class ReportResolutionResponse {

    private Long id;
    private String summary;
    private String workPerformed;
    private String publicNote;
    private String resolvedByName;
    private LocalDateTime resolvedAt;
    private LocalDateTime citizenConfirmedAt;
    private List<ReportImageResponse> images;
}
