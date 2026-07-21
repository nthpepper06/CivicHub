package com.civichub.user.repository;

import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.entity.User;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    Optional<User> findByEmail(String email);

    @EntityGraph(attributePaths = "department")
    @Query("select u from User u where u.id = :id")
    Optional<User> findWithDepartmentById(@Param("id") Long id);

    @Override
    @EntityGraph(attributePaths = "department")
    Page<User> findAll(Specification<User> specification, Pageable pageable);

    boolean existsByEmail(String email);

    long countByRole(UserRole role);

    long countByRoleAndStatusAndIsActiveTrue(UserRole role, UserStatus status);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("""
            select u from User u
            where u.role = :role
              and u.status = :status
              and u.isActive = true
            """)
    List<User> findActiveUsersByRoleAndStatusForUpdate(
            @Param("role") UserRole role,
            @Param("status") UserStatus status);

    List<User> findByRoleAndStatusAndIsActiveTrueAndDepartmentId(
            UserRole role,
            UserStatus status,
            Long departmentId);
}
