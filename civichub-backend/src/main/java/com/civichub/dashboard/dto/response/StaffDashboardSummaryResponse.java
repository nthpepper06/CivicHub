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
public class StaffDashboardSummaryResponse {

    private long pendingReports;
    private long receivedReports;
    private long inProgressReports;
    private long resolvedReports;
    private long rejectedReports;
    private long cancelledReports;
    private long totalAssigned;

    public StaffDashboardSummaryResponse(
            Number pendingReports,
            Number receivedReports,
            Number inProgressReports,
            Number resolvedReports,
            Number rejectedReports,
            Number cancelledReports,
            Number totalAssigned) {
        this.pendingReports = toLong(pendingReports);
        this.receivedReports = toLong(receivedReports);
        this.inProgressReports = toLong(inProgressReports);
        this.resolvedReports = toLong(resolvedReports);
        this.rejectedReports = toLong(rejectedReports);
        this.cancelledReports = toLong(cancelledReports);
        this.totalAssigned = toLong(totalAssigned);
    }

    private long toLong(Number value) {
        return value == null ? 0L : value.longValue();
    }
}
