package com.civichub.user.service;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.dto.request.AdminUserDepartmentRequest;
import com.civichub.user.dto.request.AdminUserStatusRequest;
import com.civichub.user.dto.response.AdminUserResponse;

public interface UserService {

    PageResponse<AdminUserResponse> getUsers(
            int page,
            int size,
            String search,
            UserRole role,
            UserStatus status,
            Boolean isActive,
            Long departmentId,
            String sortBy,
            String direction);

    AdminUserResponse getUser(Long id);

    String exportUsersCsv(
            String search,
            UserRole role,
            UserStatus status,
            Boolean isActive,
            Long departmentId,
            String sortBy,
            String direction);

    AdminUserResponse updateUserStatus(Long id, AdminUserStatusRequest request);

    AdminUserResponse assignUserDepartment(Long id, AdminUserDepartmentRequest request);
}
