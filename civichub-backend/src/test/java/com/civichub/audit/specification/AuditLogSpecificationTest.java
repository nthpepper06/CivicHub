package com.civichub.audit.specification;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.audit.entity.AuditLog;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.common.enums.UserRole;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.domain.Specification;

class AuditLogSpecificationTest {

    @Test
    void actionEntityActorDateAndSearchFiltersShouldCreateSpecification() {
        Specification<AuditLog> specification = AuditLogSpecification.filter(
                AuditAction.REPORT_STATUS_CHANGED,
                AuditEntityType.REPORT,
                99L,
                7L,
                UserRole.ADMIN,
                LocalDateTime.parse("2026-01-01T00:00:00"),
                LocalDateTime.parse("2026-01-31T23:59:59"),
                "status");

        assertThat(specification).isNotNull();
    }

    @Test
    void emptyFiltersShouldStillReturnRecipientSafeSpecificationObject() {
        Specification<AuditLog> specification = AuditLogSpecification.filter(
                null,
                null,
                null,
                null,
                null,
                null,
                null,
                "   ");

        assertThat(specification).isNotNull();
    }
}
