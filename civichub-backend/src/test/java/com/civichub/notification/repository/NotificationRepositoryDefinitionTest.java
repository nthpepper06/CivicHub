package com.civichub.notification.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.repository.UserRepository;
import java.lang.reflect.Method;
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
}
