package com.civichub.user.repository;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.entity.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    boolean existsByEmail(String email);

    long countByRole(UserRole role);

    List<User> findByRoleAndStatusAndIsActiveTrueAndDepartmentId(
            UserRole role,
            UserStatus status,
            Long departmentId);
}
