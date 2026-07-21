package com.civichub.user.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.user.dto.request.AdminUserDepartmentRequest;
import com.civichub.user.dto.request.AdminUserStatusRequest;
import com.civichub.user.dto.response.AdminUserResponse;
import com.civichub.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "bearerAuth")
public class AdminUserController {

    private final UserService userService;

    @Operation(summary = "List users with pagination and filters")
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<AdminUserResponse>>> getUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok(ApiResponse.success(
                "Users",
                userService.getUsers(page, size, search, role, status, isActive, departmentId, sortBy, direction)));
    }

    @Operation(summary = "Export all filtered users as CSV")
    @GetMapping(value = "/export", produces = "text/csv")
    public ResponseEntity<String> exportUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserRole role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) Boolean isActive,
            @RequestParam(required = false) Long departmentId,
            @RequestParam(required = false) String sortBy,
            @RequestParam(required = false) String direction) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"civichub-users.csv\"")
                .contentType(new MediaType("text", "csv"))
                .body(userService.exportUsersCsv(search, role, status, isActive, departmentId, sortBy, direction));
    }

    @Operation(summary = "Get user detail")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AdminUserResponse>> getUser(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("User", userService.getUser(id)));
    }

    @Operation(summary = "Activate or deactivate a user account")
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<AdminUserResponse>> updateUserStatus(
            @PathVariable Long id,
            @Valid @RequestBody AdminUserStatusRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "User status updated",
                userService.updateUserStatus(id, request)));
    }

    @Operation(summary = "Assign staff user to an active department")
    @PatchMapping("/{id}/department")
    public ResponseEntity<ApiResponse<AdminUserResponse>> assignUserDepartment(
            @PathVariable Long id,
            @Valid @RequestBody AdminUserDepartmentRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "User department updated",
                userService.assignUserDepartment(id, request)));
    }
}
