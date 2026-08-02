package com.civichub.config;

import com.civichub.audit.enums.AuditAction;
import com.civichub.audit.enums.AuditEntityType;
import com.civichub.common.enums.NotificationType;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import javax.sql.DataSource;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.datasource.init.ResourceDatabasePopulator;

@RequiredArgsConstructor
@Slf4j
public class DatabaseCompatibilityService {

    private static final String AUDIT_ACTION_CONSTRAINT_SCRIPT =
            "db/manual/20260722_sync_audit_log_action_check.sql";
    private static final String NOTIFICATION_TYPE_CONSTRAINT_SCRIPT =
            "db/manual/20260722_sync_notification_type_check.sql";
    private static final String REPORT_RESOLUTION_WORKFLOW_SCRIPT =
            "db/manual/20260802_create_report_resolution_workflow.sql";

    private final ObjectProvider<DataSource> dataSourceProvider;
    private final AtomicBoolean auditLogActionConstraintSynchronized = new AtomicBoolean(false);
    private final AtomicBoolean notificationTypeConstraintSynchronized = new AtomicBoolean(false);
    private final AtomicBoolean reportResolutionWorkflowSynchronized = new AtomicBoolean(false);

    public void synchronizeCompatibilityConstraintsIfNeeded() throws Exception {
        synchronizeAuditLogActionConstraintIfNeeded();
        synchronizeNotificationTypeConstraintIfNeeded();
        synchronizeReportResolutionWorkflowIfNeeded();
    }

    public void synchronizeAuditLogActionConstraintIfNeeded() throws Exception {
        if (auditLogActionConstraintSynchronized.get()) {
            return;
        }

        synchronized (auditLogActionConstraintSynchronized) {
            if (auditLogActionConstraintSynchronized.get()) {
                return;
            }

            DataSource dataSource = dataSourceProvider.getIfAvailable();
            if (dataSource == null || !isPostgreSqlWithAuditLogTable(dataSource)) {
                auditLogActionConstraintSynchronized.set(true);
                return;
            }

            if (isAuditLogConstraintCurrent(dataSource)) {
                auditLogActionConstraintSynchronized.set(true);
                log.debug("Audit log action check constraint is already synchronized.");
                return;
            }

            ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
                    new ClassPathResource(AUDIT_ACTION_CONSTRAINT_SCRIPT));
            populator.execute(dataSource);
            auditLogActionConstraintSynchronized.set(true);
            log.info("Synchronized audit log action check constraint.");
        }
    }

    public void synchronizeNotificationTypeConstraintIfNeeded() throws Exception {
        if (notificationTypeConstraintSynchronized.get()) {
            return;
        }

        synchronized (notificationTypeConstraintSynchronized) {
            if (notificationTypeConstraintSynchronized.get()) {
                return;
            }

            DataSource dataSource = dataSourceProvider.getIfAvailable();
            if (dataSource == null || !isPostgreSqlWithTable(dataSource, "notifications")) {
                notificationTypeConstraintSynchronized.set(true);
                return;
            }

            if (isNotificationTypeConstraintCurrent(dataSource)) {
                notificationTypeConstraintSynchronized.set(true);
                log.debug("Notification type check constraint is already current.");
                return;
            }

            ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
                    new ClassPathResource(NOTIFICATION_TYPE_CONSTRAINT_SCRIPT));
            populator.execute(dataSource);
            notificationTypeConstraintSynchronized.set(true);
            log.info("Synchronized notification type check constraint.");
        }
    }

    public void synchronizeReportResolutionWorkflowIfNeeded() throws Exception {
        if (reportResolutionWorkflowSynchronized.get()) {
            return;
        }

        synchronized (reportResolutionWorkflowSynchronized) {
            if (reportResolutionWorkflowSynchronized.get()) {
                return;
            }

            DataSource dataSource = dataSourceProvider.getIfAvailable();
            if (dataSource == null || !isPostgreSqlWithTable(dataSource, "reports")) {
                reportResolutionWorkflowSynchronized.set(true);
                return;
            }

            if (isPostgreSqlWithTable(dataSource, "report_timeline_events")
                    && isPostgreSqlWithTable(dataSource, "report_resolutions")
                    && isPostgreSqlWithTable(dataSource, "report_resolution_images")
                    && isPostgreSqlWithTable(dataSource, "report_ratings")) {
                reportResolutionWorkflowSynchronized.set(true);
                log.debug("Report resolution workflow tables are already current.");
                return;
            }

            ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
                    new ClassPathResource(REPORT_RESOLUTION_WORKFLOW_SCRIPT));
            populator.execute(dataSource);
            reportResolutionWorkflowSynchronized.set(true);
            log.info("Synchronized report resolution workflow tables.");
        }
    }

    private boolean isPostgreSqlWithAuditLogTable(DataSource dataSource) throws Exception {
        return isPostgreSqlWithTable(dataSource, "audit_logs");
    }

    private boolean isPostgreSqlWithTable(DataSource dataSource, String tableName) throws Exception {
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            String productName = metaData.getDatabaseProductName();
            if (productName == null || !productName.toLowerCase().contains("postgresql")) {
                return false;
            }

            try (PreparedStatement statement = connection.prepareStatement(
                    "select to_regclass(?) is not null or to_regclass(?) is not null")) {
                statement.setString(1, tableName);
                statement.setString(2, "public." + tableName);
                try (ResultSet resultSet = statement.executeQuery()) {
                    return resultSet.next() && resultSet.getBoolean(1);
                }
            }
        }
    }

    private boolean isAuditLogConstraintCurrent(DataSource dataSource) throws Exception {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("""
                        select conname, pg_get_constraintdef(oid)
                        from pg_constraint
                        where conrelid = coalesce(to_regclass('audit_logs'), to_regclass('public.audit_logs'))
                          and conname in ('audit_logs_action_check', 'audit_logs_entity_type_check')
                        """);
                ResultSet resultSet = statement.executeQuery()) {
            Map<String, String> definitions = new HashMap<>();
            while (resultSet.next()) {
                definitions.put(resultSet.getString(1), resultSet.getString(2));
            }

            return containsEveryValue(
                    definitions.get("audit_logs_action_check"),
                    EnumSet.allOf(AuditAction.class))
                    && containsEveryValue(
                            definitions.get("audit_logs_entity_type_check"),
                            EnumSet.allOf(AuditEntityType.class));
        }
    }

    private boolean isNotificationTypeConstraintCurrent(DataSource dataSource) throws Exception {
        try (Connection connection = dataSource.getConnection();
                PreparedStatement statement = connection.prepareStatement("""
                        select conname, pg_get_constraintdef(oid)
                        from pg_constraint
                        where conrelid = coalesce(to_regclass('notifications'), to_regclass('public.notifications'))
                          and conname = 'notifications_type_check'
                        """);
                ResultSet resultSet = statement.executeQuery()) {
            String definition = null;
            if (resultSet.next()) {
                definition = resultSet.getString(2);
            }

            return containsEveryValue(definition, EnumSet.allOf(NotificationType.class));
        }
    }

    private boolean containsEveryValue(String constraintDefinition, Iterable<? extends Enum<?>> values) {
        if (constraintDefinition == null || constraintDefinition.isBlank()) {
            return false;
        }
        for (Enum<?> value : values) {
            if (!constraintDefinition.contains("'" + value.name() + "'")) {
                return false;
            }
        }
        return true;
    }
}
