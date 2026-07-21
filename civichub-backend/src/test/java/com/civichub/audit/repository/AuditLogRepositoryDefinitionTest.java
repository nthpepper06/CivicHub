package com.civichub.audit.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.audit.entity.AuditLog;
import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import jakarta.persistence.Column;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Path;
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

    @Test
    void manualAuditActionConstraintScriptShouldIncludeEveryAuditAction() throws Exception {
        String migration = Files.readString(Path.of(
                "src/main/resources/db/manual/20260722_sync_audit_log_action_check.sql"));

        assertThat(AuditAction.values())
                .extracting(Enum::name)
                .allSatisfy(action -> assertThat(migration).contains("'" + action + "'"));
    }

    @Test
    void manualAuditConstraintScriptShouldIncludeEveryAuditEntityType() throws Exception {
        String migration = Files.readString(Path.of(
                "src/main/resources/db/manual/20260722_sync_audit_log_action_check.sql"));

        assertThat(AuditEntityType.values())
                .extracting(Enum::name)
                .allSatisfy(entityType -> assertThat(migration).contains("'" + entityType + "'"));
    }
}
