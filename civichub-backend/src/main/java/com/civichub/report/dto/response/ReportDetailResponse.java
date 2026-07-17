package com.civichub.report.dto.response;

import com.civichub.common.enums.ReportStatus;
import java.math.BigDecimal;
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
public class ReportDetailResponse {

    private Long id;
    private String title;
    private String description;
    private String address;
    private BigDecimal latitude;
    private BigDecimal longitude;
    private ReportStatus status;
    private Long categoryId;
    private String categoryName;
    private Long departmentId;
    private String departmentName;
    private Long citizenId;
    private String citizenName;
    private List<ReportImageResponse> images;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
