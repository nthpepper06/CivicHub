package com.civichub.report.dto.response;

import com.civichub.common.enums.ReportStatus;
import java.time.LocalDateTime;
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
public class ReportSummaryResponse {

    private Long id;
    private String title;
    private String address;
    private ReportStatus status;
    private Long categoryId;
    private String categoryName;
    private Long departmentId;
    private String departmentName;
    private Long citizenId;
    private String citizenName;
    private String primaryImageUrl;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
