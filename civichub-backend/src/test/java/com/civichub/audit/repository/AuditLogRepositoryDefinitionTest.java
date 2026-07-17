package com.civichub.audit.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.audit.entity.AuditLog;
import jakarta.persistence.Column;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.lang.reflect.Field;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

class AuditLogRepositoryDefinitionTest {

    @Test
    void repositoryShouldSupportJpaAndSpecificationsOnly() {
        assertThat(JpaRepository.class).isAssignableFrom(AuditLogRepository.class);
        assertThat(JpaSpecificationExecutor.class).isAssignableFrom(AuditLogRepository.class);
    }

    @Test
    void auditLogShouldUseUsefulIndexes() {
        Table table = AuditLog.class.getAnnotation(Table.class);

        assertThat(table).isNotNull();
        assertThat(table.name()).isEqualTo("audit_logs");
        assertThat(table.indexes())
                .extracting(Index::columnList)
                .contains(
                        "created_at",
                        "action, created_at",
                        "entity_type, entity_id",
                        "actor_id, created_at");
    }

    @Test
    void oldAndNewValuesShouldUseTextColumns() throws Exception {
        Field oldValues = AuditLog.class.getDeclaredField("oldValues");
        Field newValues = AuditLog.class.getDeclaredField("newValues");

        assertThat(oldValues.getAnnotation(Column.class).columnDefinition()).isEqualTo("TEXT");
        assertThat(newValues.getAnnotation(Column.class).columnDefinition()).isEqualTo("TEXT");
    }
}
