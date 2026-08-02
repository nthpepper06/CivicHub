package com.civichub.report.dto.request;

import com.civichub.common.enums.ReportStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class ReportStatusUpdateRequest {

    @NotNull
    private ReportStatus status;

    @Size(max = 1000)
    private String resolutionSummary;

    @Size(max = 5000)
    private String workPerformed;

    @Size(max = 5000)
    private String publicNote;

    @Size(max = 5)
    private List<@Size(max = 2000) String> resolutionImageUrls;

    public ReportStatusUpdateRequest(ReportStatus status) {
        this.status = status;
    }
}
