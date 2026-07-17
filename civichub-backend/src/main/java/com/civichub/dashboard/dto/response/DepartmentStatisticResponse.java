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
public class DepartmentStatisticResponse {

    private Long departmentId;
    private String departmentName;
    private long totalReports;

    public DepartmentStatisticResponse(Long departmentId, String departmentName, Number totalReports) {
        this.departmentId = departmentId;
        this.departmentName = departmentName;
        this.totalReports = totalReports == null ? 0L : totalReports.longValue();
    }
}
