package com.civichub.user.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.audit.service.AuditService;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.dto.request.AdminUserDepartmentRequest;
import com.civichub.user.dto.request.AdminUserStatusRequest;
import com.civichub.user.entity.User;
import com.civichub.user.mapper.UserMapper;
import com.civichub.user.repository.UserRepository;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;

@ExtendWith(MockitoExtension.class)
class UserServiceImplTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private AuditService auditService;

    private UserServiceImpl userService;

    @BeforeEach
    void setUp() {
        userService = new UserServiceImpl(
                userRepository,
                departmentRepository,
                new UserMapper(),
                auditService);
    }

    @AfterEach
    void tearDown() {
        SecurityContextHolder.clearContext();
    }

    @Test
    void listUsersShouldUseSafePagingAndNeverExposePasswordInResponse() {
        User user = user(1L, UserRole.CITIZEN, true);
        when(userRepository.findAll(anyUserSpecification(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(user)));

        var response = userService.getUsers(0, 250, "citizen", UserRole.CITIZEN, UserStatus.ACTIVE,
                true, null, "email", "ASC");

        ArgumentCaptor<Pageable> pageableCaptor = ArgumentCaptor.forClass(Pageable.class);
        verify(userRepository).findAll(anyUserSpecification(), pageableCaptor.capture());
        assertThat(pageableCaptor.getValue().getPageSize()).isEqualTo(100);
        assertThat(pageableCaptor.getValue().getSort().getOrderFor("email").isAscending()).isTrue();
        assertThat(response.getContent()).hasSize(1);
        assertThat(response.getContent().getFirst().getEmail()).isEqualTo("user1@example.com");
    }

    @Test
    void getUserShouldUseDepartmentAwareLookup() {
        User user = user(1L, UserRole.STAFF, true);
        user.setDepartment(department(true));
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(user));

        var response = userService.getUser(1L);

        assertThat(response.getDepartmentName()).isEqualTo("Urban Services");
    }

    @Test
    void missingUserShouldReturnNotFound() {
        when(userRepository.findWithDepartmentById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> userService.getUser(99L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void deactivateUserShouldUpdateStatusAndAudit() {
        authenticate(99L, UserRole.ADMIN);
        User citizen = user(1L, UserRole.CITIZEN, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(citizen));
        when(userRepository.save(citizen)).thenReturn(citizen);

        var response = userService.updateUserStatus(1L, new AdminUserStatusRequest(false));

        assertThat(response.isActive()).isFalse();
        assertThat(citizen.getStatus()).isEqualTo(UserStatus.INACTIVE);
        verify(auditService).recordUserStatusChanged(citizen, true, false, UserStatus.ACTIVE, UserStatus.INACTIVE);
    }

    @Test
    void adminCannotDeactivateOwnAccount() {
        authenticate(1L, UserRole.ADMIN);
        User admin = user(1L, UserRole.ADMIN, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(admin));

        assertThatThrownBy(() -> userService.updateUserStatus(1L, new AdminUserStatusRequest(false)))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Cannot deactivate your own administrator account");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void adminCannotDeactivateLastActiveAdmin() {
        authenticate(99L, UserRole.ADMIN);
        User admin = user(1L, UserRole.ADMIN, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(admin));
        when(userRepository.findActiveUsersByRoleAndStatusForUpdate(UserRole.ADMIN, UserStatus.ACTIVE))
                .thenReturn(List.of(admin));

        assertThatThrownBy(() -> userService.updateUserStatus(1L, new AdminUserStatusRequest(false)))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Cannot deactivate the last active administrator");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void deactivateAdminShouldLockActiveAdminsAndAllowWhenAnotherAdminRemains() {
        authenticate(99L, UserRole.ADMIN);
        User targetAdmin = user(1L, UserRole.ADMIN, true);
        User otherAdmin = user(2L, UserRole.ADMIN, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(targetAdmin));
        when(userRepository.findActiveUsersByRoleAndStatusForUpdate(UserRole.ADMIN, UserStatus.ACTIVE))
                .thenReturn(List.of(targetAdmin, otherAdmin));
        when(userRepository.save(targetAdmin)).thenReturn(targetAdmin);

        var response = userService.updateUserStatus(1L, new AdminUserStatusRequest(false));

        assertThat(response.isActive()).isFalse();
        verify(userRepository).findActiveUsersByRoleAndStatusForUpdate(UserRole.ADMIN, UserStatus.ACTIVE);
        verify(auditService).recordUserStatusChanged(
                targetAdmin,
                true,
                false,
                UserStatus.ACTIVE,
                UserStatus.INACTIVE);
    }

    @Test
    void assignDepartmentShouldOnlyAllowStaffUsers() {
        User citizen = user(1L, UserRole.CITIZEN, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(citizen));

        assertThatThrownBy(() -> userService.assignUserDepartment(1L, new AdminUserDepartmentRequest(5L)))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Only staff users can be assigned to a department");
        verify(departmentRepository, never()).findById(any());
    }

    @Test
    void assignDepartmentShouldRejectInactiveDepartment() {
        User staff = user(1L, UserRole.STAFF, true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(staff));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department(false)));

        assertThatThrownBy(() -> userService.assignUserDepartment(1L, new AdminUserDepartmentRequest(5L)))
                .isInstanceOf(InvalidReportStateException.class)
                .hasMessage("Department is inactive");
        verify(userRepository, never()).save(any(User.class));
    }

    @Test
    void assignDepartmentShouldSaveStaffDepartmentAndAudit() {
        User staff = user(1L, UserRole.STAFF, true);
        Department department = department(true);
        when(userRepository.findWithDepartmentById(1L)).thenReturn(Optional.of(staff));
        when(departmentRepository.findById(5L)).thenReturn(Optional.of(department));
        when(userRepository.save(staff)).thenReturn(staff);

        var response = userService.assignUserDepartment(1L, new AdminUserDepartmentRequest(5L));

        assertThat(response.getDepartmentId()).isEqualTo(5L);
        verify(auditService).recordUserDepartmentChanged(staff, null, department);
    }

    private void authenticate(Long userId, UserRole role) {
        CivicHubUserPrincipal principal = new CivicHubUserPrincipal(
                userId,
                "admin@example.com",
                "encoded",
                role,
                true);
        SecurityContextHolder.getContext().setAuthentication(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
    }

    private Specification<User> anyUserSpecification() {
        return any();
    }

    private User user(Long id, UserRole role, boolean active) {
        return User.builder()
                .id(id)
                .fullName("User " + id)
                .email("user" + id + "@example.com")
                .password("encoded")
                .role(role)
                .status(active ? UserStatus.ACTIVE : UserStatus.INACTIVE)
                .isActive(active)
                .build();
    }

    private Department department(boolean active) {
        return Department.builder()
                .id(5L)
                .name("Urban Services")
                .isActive(active)
                .build();
    }
}
