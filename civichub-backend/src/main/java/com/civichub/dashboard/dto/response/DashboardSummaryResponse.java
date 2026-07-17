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
public class DashboardSummaryResponse {

    private long totalReports;
    private long pendingReports;
    private long receivedReports;
    private long inProgressReports;
    private long resolvedReports;
    private long rejectedReports;
    private long cancelledReports;
    private long totalCitizens;
    private long totalStaff;
    private long totalDepartments;
    private long totalCategories;
}
