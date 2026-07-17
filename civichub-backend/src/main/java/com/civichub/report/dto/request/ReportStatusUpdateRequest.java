package com.civichub.report.dto.request;

import com.civichub.common.enums.ReportStatus;
import jakarta.validation.constraints.NotNull;
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
}
