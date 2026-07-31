package com.civichub.config;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.common.enums.NotificationType;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.sql.DataSource;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.ObjectProvider;

class DatabaseCompatibilityServiceTest {

    @Test
    void synchronizationUpdatesStalePostgreSqlConstraint() throws Exception {
        DataSource dataSource = mock(DataSource.class);
        Connection tableCheckConnection = postgreSqlConnection();
        Connection constraintCheckConnection = mock(Connection.class);
        Connection scriptConnection = mock(Connection.class);
        Statement scriptStatement = mock(Statement.class);
        PreparedStatement tableExistsStatement = statementWithBooleanResult(true);
        PreparedStatement staleConstraintStatement = constraintStatement(
                actionDefinition("'CATEGORY_CREATED'"),
                entityTypeDefinition("'CATEGORY'"));

        when(dataSource.getConnection())
                .thenReturn(tableCheckConnection, constraintCheckConnection, scriptConnection);
        when(tableCheckConnection.prepareStatement(anyString())).thenReturn(tableExistsStatement);
        when(constraintCheckConnection.prepareStatement(anyString())).thenReturn(staleConstraintStatement);
        when(scriptConnection.createStatement()).thenReturn(scriptStatement);

        DatabaseCompatibilityService service = new DatabaseCompatibilityService(provider(dataSource));

        service.synchronizeAuditLogActionConstraintIfNeeded();

        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains(
                "drop constraint if exists audit_logs_action_check"));
        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains("'REPORT_ASSIGNED'"));
        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains("'REPORT_REASSIGNED'"));
    }

    @Test
    void synchronizationIsIdempotentWhenConstraintIsAlreadyCurrent() throws Exception {
        DataSource dataSource = mock(DataSource.class);
        Connection tableCheckConnection = postgreSqlConnection();
        Connection constraintCheckConnection = mock(Connection.class);
        PreparedStatement tableExistsStatement = statementWithBooleanResult(true);
        PreparedStatement currentConstraintStatement = constraintStatement(
                actionDefinition(
                        "'CATEGORY_CREATED'",
                        "'CATEGORY_UPDATED'",
                        "'CATEGORY_ACTIVATED'",
                        "'CATEGORY_DEACTIVATED'",
                        "'DEPARTMENT_CREATED'",
                        "'DEPARTMENT_UPDATED'",
                        "'DEPARTMENT_ACTIVATED'",
                        "'DEPARTMENT_DEACTIVATED'",
                        "'REPORT_ASSIGNED'",
                        "'REPORT_REASSIGNED'",
                        "'REPORT_STATUS_CHANGED'",
                        "'REPORT_CANCELLED'",
                        "'PROFILE_UPDATED'",
                        "'PASSWORD_CHANGED'",
                        "'USER_STATUS_CHANGED'",
                        "'USER_DEPARTMENT_CHANGED'"),
                entityTypeDefinition("'CATEGORY'", "'DEPARTMENT'", "'REPORT'", "'USER'"));

        when(dataSource.getConnection()).thenReturn(tableCheckConnection, constraintCheckConnection);
        when(tableCheckConnection.prepareStatement(anyString())).thenReturn(tableExistsStatement);
        when(constraintCheckConnection.prepareStatement(anyString())).thenReturn(currentConstraintStatement);

        DatabaseCompatibilityService service = new DatabaseCompatibilityService(provider(dataSource));

        service.synchronizeAuditLogActionConstraintIfNeeded();
        service.synchronizeAuditLogActionConstraintIfNeeded();

        verify(dataSource, org.mockito.Mockito.times(2)).getConnection();
        verify(constraintCheckConnection, never()).createStatement();
    }

    @Test
    void synchronizationSkipsNonPostgreSqlDatabases() throws Exception {
        DataSource dataSource = mock(DataSource.class);
        Connection connection = mock(Connection.class);
        DatabaseMetaData metaData = mock(DatabaseMetaData.class);
        when(dataSource.getConnection()).thenReturn(connection);
        when(connection.getMetaData()).thenReturn(metaData);
        when(metaData.getDatabaseProductName()).thenReturn("H2");

        DatabaseCompatibilityService service = new DatabaseCompatibilityService(provider(dataSource));

        assertThatCode(service::synchronizeAuditLogActionConstraintIfNeeded).doesNotThrowAnyException();

        verify(connection, never()).createStatement();
    }

    @Test
    void notificationSynchronizationUpdatesStalePostgreSqlConstraint() throws Exception {
        DataSource dataSource = mock(DataSource.class);
        Connection tableCheckConnection = postgreSqlConnection();
        Connection constraintCheckConnection = mock(Connection.class);
        Connection scriptConnection = mock(Connection.class);
        Statement scriptStatement = mock(Statement.class);
        PreparedStatement tableExistsStatement = statementWithBooleanResult(true);
        PreparedStatement staleConstraintStatement = notificationTypeConstraintStatement(
                typeDefinition("'LEGACY_NOTIFICATION'"));

        when(dataSource.getConnection())
                .thenReturn(tableCheckConnection, constraintCheckConnection, scriptConnection);
        when(tableCheckConnection.prepareStatement(anyString())).thenReturn(tableExistsStatement);
        when(constraintCheckConnection.prepareStatement(anyString())).thenReturn(staleConstraintStatement);
        when(scriptConnection.createStatement()).thenReturn(scriptStatement);

        DatabaseCompatibilityService service = new DatabaseCompatibilityService(provider(dataSource));

        service.synchronizeNotificationTypeConstraintIfNeeded();

        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains(
                "drop constraint if exists notifications_type_check"));
        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains("'REPORT_ASSIGNED'"));
        verify(scriptStatement).execute(org.mockito.ArgumentMatchers.contains("'REPORT_STATUS_CHANGED'"));
    }

    @Test
    void notificationSynchronizationIsIdempotentWhenConstraintIsAlreadyCurrent() throws Exception {
        DataSource dataSource = mock(DataSource.class);
        Connection tableCheckConnection = postgreSqlConnection();
        Connection constraintCheckConnection = mock(Connection.class);
        PreparedStatement tableExistsStatement = statementWithBooleanResult(true);
        PreparedStatement currentConstraintStatement = notificationTypeConstraintStatement(
                typeDefinition(notificationTypeNames()));

        when(dataSource.getConnection()).thenReturn(tableCheckConnection, constraintCheckConnection);
        when(tableCheckConnection.prepareStatement(anyString())).thenReturn(tableExistsStatement);
        when(constraintCheckConnection.prepareStatement(anyString())).thenReturn(currentConstraintStatement);

        DatabaseCompatibilityService service = new DatabaseCompatibilityService(provider(dataSource));

        service.synchronizeNotificationTypeConstraintIfNeeded();
        service.synchronizeNotificationTypeConstraintIfNeeded();

        verify(dataSource, org.mockito.Mockito.times(2)).getConnection();
        verify(constraintCheckConnection, never()).createStatement();
    }

    private Connection postgreSqlConnection() throws Exception {
        Connection connection = mock(Connection.class);
        DatabaseMetaData metaData = mock(DatabaseMetaData.class);
        when(connection.getMetaData()).thenReturn(metaData);
        when(metaData.getDatabaseProductName()).thenReturn("PostgreSQL");
        return connection;
    }

    private PreparedStatement statementWithBooleanResult(boolean value) throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet resultSet = mock(ResultSet.class);
        when(statement.executeQuery()).thenReturn(resultSet);
        when(resultSet.next()).thenReturn(true, false);
        when(resultSet.getBoolean(1)).thenReturn(value);
        return statement;
    }

    private PreparedStatement constraintStatement(String actionDefinition, String entityTypeDefinition) throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet resultSet = mock(ResultSet.class);
        when(statement.executeQuery()).thenReturn(resultSet);
        when(resultSet.next()).thenReturn(true, true, false);
        when(resultSet.getString(1))
                .thenReturn("audit_logs_action_check", "audit_logs_entity_type_check");
        when(resultSet.getString(2)).thenReturn(actionDefinition, entityTypeDefinition);
        return statement;
    }

    private PreparedStatement notificationTypeConstraintStatement(String typeDefinition) throws Exception {
        PreparedStatement statement = mock(PreparedStatement.class);
        ResultSet resultSet = mock(ResultSet.class);
        when(statement.executeQuery()).thenReturn(resultSet);
        when(resultSet.next()).thenReturn(true, false);
        when(resultSet.getString(1)).thenReturn("notifications_type_check");
        when(resultSet.getString(2)).thenReturn(typeDefinition);
        return statement;
    }

    private String actionDefinition(String... actions) {
        return "CHECK (action in (" + String.join(",", actions) + "))";
    }

    private String entityTypeDefinition(String... entityTypes) {
        return "CHECK (entity_type in (" + String.join(",", entityTypes) + "))";
    }

    private String typeDefinition(String... types) {
        return "CHECK (type in (" + String.join(",", types) + "))";
    }

    private String[] notificationTypeNames() {
        return java.util.Arrays.stream(NotificationType.values())
                .map(type -> "'" + type.name() + "'")
                .toArray(String[]::new);
    }

    private ObjectProvider<DataSource> provider(DataSource dataSource) {
        @SuppressWarnings("unchecked")
        ObjectProvider<DataSource> provider = mock(ObjectProvider.class);
        lenient().when(provider.getIfAvailable()).thenReturn(dataSource);
        return provider;
    }
}
