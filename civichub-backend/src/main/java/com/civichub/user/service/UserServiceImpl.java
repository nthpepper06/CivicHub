package com.civichub.user.service;

import com.civichub.audit.service.AuditService;
import com.civichub.common.CsvUtils;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.common.exception.InvalidReportStateException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.entity.Department;
import com.civichub.department.repository.DepartmentRepository;
import com.civichub.security.CivicHubUserPrincipal;
import com.civichub.user.dto.request.AdminUserDepartmentRequest;
import com.civichub.user.dto.request.AdminUserStatusRequest;
import com.civichub.user.dto.response.AdminUserResponse;
import com.civichub.user.entity.User;
import com.civichub.user.mapper.UserMapper;
import com.civichub.user.repository.UserRepository;
import com.civichub.user.specification.UserSpecification;
import java.util.List;
import java.util.Set;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private static final int DEFAULT_PAGE_SIZE = 10;
    private static final int MAX_PAGE_SIZE = 100;
    private static final int MAX_EXPORT_SIZE = 5000;
    private static final Set<String> ALLOWED_SORT_FIELDS =
            Set.of("createdAt", "updatedAt", "fullName", "email", "role", "status");

    private final UserRepository userRepository;
    private final DepartmentRepository departmentRepository;
    private final UserMapper userMapper;
    private final AuditService auditService;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<AdminUserResponse> getUsers(
            int page,
            int size,
            String search,
            UserRole role,
            UserStatus status,
            Boolean isActive,
            Long departmentId,
            String sortBy,
            String direction) {
        Page<User> users = userRepository.findAll(
                UserSpecification.filter(search, role, status, isActive, departmentId),
                pageable(page, size, sortBy, direction));
        return toPageResponse(users.map(userMapper::toAdminResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public AdminUserResponse getUser(Long id) {
        return userMapper.toAdminResponse(findUser(id));
    }

    @Override
    @Transactional(readOnly = true)
    public String exportUsersCsv(
            String search,
            UserRole role,
            UserStatus status,
            Boolean isActive,
            Long departmentId,
            String sortBy,
            String direction) {
        Page<User> users = userRepository.findAll(
                UserSpecification.filter(search, role, status, isActive, departmentId),
                pageable(0, MAX_EXPORT_SIZE, sortBy, direction));
        StringBuilder csv = new StringBuilder('\ufeff' + CsvUtils.row(
                CsvUtils.trusted("ID"),
                CsvUtils.trusted("Full Name"),
                CsvUtils.trusted("Email"),
                CsvUtils.trusted("Phone"),
                CsvUtils.trusted("Role"),
                CsvUtils.trusted("Status"),
                CsvUtils.trusted("Active"),
                CsvUtils.trusted("Department"),
                CsvUtils.trusted("Created At"),
                CsvUtils.trusted("Updated At")));
        users.getContent().forEach(user -> csv.append('\n').append(CsvUtils.row(
                CsvUtils.trusted(user.getId()),
                CsvUtils.text(user.getFullName()),
                CsvUtils.text(user.getEmail()),
                CsvUtils.text(user.getPhone()),
                CsvUtils.trusted(user.getRole()),
                CsvUtils.trusted(user.getStatus()),
                CsvUtils.trusted(user.isActive()),
                CsvUtils.text(user.getDepartment() == null ? null : user.getDepartment().getName()),
                CsvUtils.trusted(user.getCreatedAt()),
                CsvUtils.trusted(user.getUpdatedAt()))));
        return csv.toString();
    }

    @Override
    @Transactional
    public AdminUserResponse updateUserStatus(Long id, AdminUserStatusRequest request) {
        User user = findUser(id);
        boolean newActive = Boolean.TRUE.equals(request.getIsActive());
        UserStatus newStatus = newActive ? UserStatus.ACTIVE : UserStatus.INACTIVE;
        boolean oldActive = user.isActive();
        UserStatus oldStatus = user.getStatus();

        if (oldActive == newActive && oldStatus == newStatus) {
            return userMapper.toAdminResponse(user);
        }

        if (!newActive && UserRole.ADMIN.equals(user.getRole())) {
            ensureAdminCanBeDeactivated(user);
        }

        user.setActive(newActive);
        user.setStatus(newStatus);
        User savedUser = userRepository.save(user);
        auditService.recordUserStatusChanged(savedUser, oldActive, newActive, oldStatus, newStatus);
        return userMapper.toAdminResponse(savedUser);
    }

    @Override
    @Transactional
    public AdminUserResponse assignUserDepartment(Long id, AdminUserDepartmentRequest request) {
        User user = findUser(id);
        if (!UserRole.STAFF.equals(user.getRole())) {
            throw new InvalidReportStateException("Only staff users can be assigned to a department");
        }
        Department department = departmentRepository.findById(request.getDepartmentId())
                .orElseThrow(() -> new ResourceNotFoundException("Department not found"));
        if (!department.isActive()) {
            throw new InvalidReportStateException("Department is inactive");
        }
        Department oldDepartment = user.getDepartment();
        Long oldDepartmentId = oldDepartment == null ? null : oldDepartment.getId();
        if (department.getId().equals(oldDepartmentId)) {
            return userMapper.toAdminResponse(user);
        }

        user.setDepartment(department);
        User savedUser = userRepository.save(user);
        auditService.recordUserDepartmentChanged(savedUser, oldDepartment, department);
        return userMapper.toAdminResponse(savedUser);
    }

    private void ensureAdminCanBeDeactivated(User user) {
        Long currentUserId = currentPrincipal().getUserId();
        if (user.getId().equals(currentUserId)) {
            throw new InvalidReportStateException("Cannot deactivate your own administrator account");
        }
        List<User> activeAdmins = userRepository.findActiveUsersByRoleAndStatusForUpdate(
                UserRole.ADMIN,
                UserStatus.ACTIVE);
        if (activeAdmins.size() <= 1) {
            throw new InvalidReportStateException("Cannot deactivate the last active administrator");
        }
    }

    private User findUser(Long id) {
        return userRepository.findWithDepartmentById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private CivicHubUserPrincipal currentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !(authentication.getPrincipal() instanceof CivicHubUserPrincipal principal)) {
            throw new ResourceNotFoundException("Current user not found");
        }
        return principal;
    }

    private Pageable pageable(int page, int size, String sortBy, String direction) {
        int normalizedPage = Math.max(page, 0);
        int normalizedSize = size <= 0 ? DEFAULT_PAGE_SIZE : Math.min(size, MAX_PAGE_SIZE);
        String safeSortBy = ALLOWED_SORT_FIELDS.contains(sortBy) ? sortBy : "createdAt";
        Sort.Direction safeDirection = "ASC".equalsIgnoreCase(direction) ? Sort.Direction.ASC : Sort.Direction.DESC;
        return PageRequest.of(normalizedPage, normalizedSize, Sort.by(safeDirection, safeSortBy));
    }

    private PageResponse<AdminUserResponse> toPageResponse(Page<AdminUserResponse> page) {
        return PageResponse.<AdminUserResponse>builder()
                .content(page.getContent())
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .first(page.isFirst())
                .last(page.isLast())
                .build();
    }
}
