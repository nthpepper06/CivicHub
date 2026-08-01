package com.civichub.common;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.common.enums.NotificationType;
import com.civichub.common.enums.ReportStatus;
import org.junit.jupiter.api.Test;

class SystemContractTest {

    @Test
    void reportStatusesRemainSynchronizedWithMobileAndAdminClients() {
        assertThat(ReportStatus.values())
                .extracting(Enum::name)
                .containsExactly(
                        "PENDING",
                        "RECEIVED",
                        "IN_PROGRESS",
                        "RESOLVED",
                        "REJECTED",
                        "CANCELLED");
    }

    @Test
    void notificationTypesRemainSynchronizedWithClientsAndDatabaseConstraint() {
        assertThat(NotificationType.values())
                .extracting(Enum::name)
                .containsExactly(
                        "REPORT_ASSIGNED",
                        "REPORT_STATUS_CHANGED");
    }
}
