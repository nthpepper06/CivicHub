package com.civichub.user.repository;

import static org.assertj.core.api.Assertions.assertThat;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import jakarta.persistence.LockModeType;
import java.lang.reflect.Method;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;

class UserRepositoryDefinitionTest {

    @Test
    void activeAdminLookupShouldUsePessimisticWriteLock() throws Exception {
        Method method = UserRepository.class.getMethod(
                "findActiveUsersByRoleAndStatusForUpdate",
                UserRole.class,
                UserStatus.class);
        Lock lock = method.getAnnotation(Lock.class);
        Query query = method.getAnnotation(Query.class);

        assertThat(lock).isNotNull();
        assertThat(lock.value()).isEqualTo(LockModeType.PESSIMISTIC_WRITE);
        assertThat(query).isNotNull();
        assertThat(query.value())
                .contains("u.role = :role")
                .contains("u.status = :status")
                .contains("u.isActive = true");
    }

    @Test
    @DisplayName("Login lookup fetches department for auth response mapping")
    void loginLookupShouldFetchDepartment() throws Exception {
        Method method = UserRepository.class.getMethod("findWithDepartmentByEmail", String.class);
        EntityGraph entityGraph = method.getAnnotation(EntityGraph.class);
        Query query = method.getAnnotation(Query.class);

        assertThat(entityGraph).isNotNull();
        assertThat(entityGraph.attributePaths()).containsExactly("department");
        assertThat(query).isNotNull();
        assertThat(query.value()).contains("where u.email = :email");
    }
}
