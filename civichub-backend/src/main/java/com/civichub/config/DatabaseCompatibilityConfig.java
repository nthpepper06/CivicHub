package com.civichub.config;

import javax.sql.DataSource;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DatabaseCompatibilityConfig {

    @Bean
    @ConditionalOnProperty(
            prefix = "app.database",
            name = "auto-sync-audit-log-actions",
            havingValue = "true",
            matchIfMissing = true)
    DatabaseCompatibilityService databaseCompatibilityService(ObjectProvider<DataSource> dataSourceProvider) {
        return new DatabaseCompatibilityService(dataSourceProvider);
    }

    @Bean
    ApplicationRunner auditLogActionConstraintSynchronizer(DatabaseCompatibilityService databaseCompatibilityService) {
        return args -> {
            databaseCompatibilityService.synchronizeAuditLogActionConstraintIfNeeded();
        };
    }
}
