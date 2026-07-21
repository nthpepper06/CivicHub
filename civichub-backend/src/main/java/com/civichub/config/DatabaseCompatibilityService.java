package com.civichub.config;

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
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

    private final ObjectProvider<DataSource> dataSourceProvider;
    private final AtomicBoolean auditLogActionConstraintSynchronized = new AtomicBoolean(false);

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

            ResourceDatabasePopulator populator = new ResourceDatabasePopulator(
                    new ClassPathResource(AUDIT_ACTION_CONSTRAINT_SCRIPT));
            populator.execute(dataSource);
            auditLogActionConstraintSynchronized.set(true);
            log.info("Synchronized audit log action check constraint.");
        }
    }

    private boolean isPostgreSqlWithAuditLogTable(DataSource dataSource) throws Exception {
        try (Connection connection = dataSource.getConnection()) {
            DatabaseMetaData metaData = connection.getMetaData();
            String productName = metaData.getDatabaseProductName();
            if (productName == null || !productName.toLowerCase().contains("postgresql")) {
                return false;
            }

            try (PreparedStatement statement = connection.prepareStatement(
                    "select to_regclass('audit_logs') is not null or to_regclass('public.audit_logs') is not null");
                    ResultSet resultSet = statement.executeQuery()) {
                return resultSet.next() && resultSet.getBoolean(1);
            }
        }
    }
}
