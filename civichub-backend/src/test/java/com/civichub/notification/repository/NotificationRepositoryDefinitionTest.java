package com.civichub.notification.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.common.enums.NotificationType;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.notification.entity.Notification;
import com.civichub.user.repository.UserRepository;
import jakarta.persistence.Column;
import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

class NotificationRepositoryDefinitionTest {

    @Test
    void recipientScopedDetailMethodShouldExist() throws Exception {
        Method method = NotificationRepository.class.getMethod("findByIdAndUserId", Long.class, Long.class);

        assertThat(method).isNotNull();
    }

    @Test
    void unreadCountMethodShouldBeRecipientScoped() throws Exception {
        Method method = NotificationRepository.class.getMethod("countByUserIdAndReadFalse", Long.class);

        assertThat(method).isNotNull();
    }

    @Test
    void bulkMarkAllReadQueryShouldBeScopedToRecipientAndUnreadRows() throws Exception {
        Method method = NotificationRepository.class.getMethod("markAllAsRead", Long.class, LocalDateTime.class);
        Query query = method.getAnnotation(Query.class);

        assertThat(method.getAnnotation(Modifying.class)).isNotNull();
        assertThat(query).isNotNull();
        assertThat(query.value())
                .contains("where n.user.id = :userId")
                .contains("and n.read = false");
    }

    @Test
    void staffRecipientLookupShouldBeRestrictedByRoleStatusActiveAndDepartment() throws Exception {
        Method method = UserRepository.class.getMethod(
                "findByRoleAndStatusAndIsActiveTrueAndDepartmentId",
                UserRole.class,
                UserStatus.class,
                Long.class);

        assertThat(method).isNotNull();
    }

    @Test
    void contentColumnShouldRemainRequiredForDatabaseCompatibility() throws Exception {
        Field field = Notification.class.getDeclaredField("content");
        Column column = field.getAnnotation(Column.class);

        assertThat(column).isNotNull();
        assertThat(column.nullable()).isFalse();
    }

    @Test
    void manualNotificationTypeConstraintScriptShouldIncludeEveryNotificationType() throws Exception {
        String migration = Files.readString(Path.of(
                "src/main/resources/db/manual/20260722_sync_notification_type_check.sql"));

        assertThat(NotificationType.values())
                .extracting(Enum::name)
                .allSatisfy(type -> assertThat(migration).contains("'" + type + "'"));
    }
}
