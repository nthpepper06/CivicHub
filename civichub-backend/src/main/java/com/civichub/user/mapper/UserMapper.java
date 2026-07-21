package com.civichub.user.mapper;

import com.civichub.user.dto.response.AdminUserResponse;
import com.civichub.user.entity.User;
import org.springframework.stereotype.Component;

@Component
public class UserMapper {

    public AdminUserResponse toAdminResponse(User user) {
        return AdminUserResponse.builder()
                .id(user.getId())
                .fullName(user.getFullName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .avatar(user.getAvatar())
                .role(user.getRole())
                .status(user.getStatus())
                .isActive(user.isActive())
                .departmentId(user.getDepartment() == null ? null : user.getDepartment().getId())
                .departmentName(user.getDepartment() == null ? null : user.getDepartment().getName())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
