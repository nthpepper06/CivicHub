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
public class MonthlyStatisticResponse {

    private int month;
    private long totalReports;
    private long resolvedReports;

    public MonthlyStatisticResponse(Number month, Number totalReports, Number resolvedReports) {
        this.month = month == null ? 0 : month.intValue();
        this.totalReports = totalReports == null ? 0L : totalReports.longValue();
        this.resolvedReports = resolvedReports == null ? 0L : resolvedReports.longValue();
    }
}
