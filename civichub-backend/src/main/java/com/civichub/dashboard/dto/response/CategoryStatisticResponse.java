package com.civichub.dashboard.dto.response;

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
public class CategoryStatisticResponse {

    private Long categoryId;
    private String categoryName;
    private long totalReports;

    public CategoryStatisticResponse(Long categoryId, String categoryName, Number totalReports) {
        this.categoryId = categoryId;
        this.categoryName = categoryName;
        this.totalReports = totalReports == null ? 0L : totalReports.longValue();
    }
}
