package com.civichub.department.controller;

import com.civichub.common.ApiResponse;
import com.civichub.common.PageResponse;
import com.civichub.department.dto.request.DepartmentCreateRequest;
import com.civichub.department.dto.request.DepartmentStatusRequest;
import com.civichub.department.dto.request.DepartmentUpdateRequest;
import com.civichub.department.dto.response.DepartmentResponse;
import com.civichub.department.service.DepartmentService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/departments")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
@SecurityRequirement(name = "bearerAuth")
public class AdminDepartmentController {

    private final DepartmentService departmentService;

    @Operation(summary = "List departments with pagination and filters")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "200", description = "Departments returned"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "401", description = "Authentication required"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "403", description = "Admin role required")
    })
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<DepartmentResponse>>> getDepartments(
            @Parameter(description = "Zero-based page index") @RequestParam(defaultValue = "0") int page,
            @Parameter(description = "Page size") @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Boolean isActive) {
        return ResponseEntity.ok(ApiResponse.success(
                "Departments",
                departmentService.getDepartments(page, size, search, isActive)));
    }

    @Operation(summary = "Get department by id")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<DepartmentResponse>> getDepartment(@PathVariable Long id) {
        return ResponseEntity.ok(ApiResponse.success("Department", departmentService.getDepartment(id)));
    }

    @Operation(summary = "Create department")
    @ApiResponses({
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "201", description = "Department created"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "400", description = "Invalid request"),
            @io.swagger.v3.oas.annotations.responses.ApiResponse(responseCode = "409", description = "Department name already exists")
    })
    @PostMapping
    public ResponseEntity<ApiResponse<DepartmentResponse>> createDepartment(
            @Valid @RequestBody DepartmentCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Department created", departmentService.createDepartment(request)));
    }

    @Operation(summary = "Update department")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<DepartmentResponse>> updateDepartment(
            @PathVariable Long id,
            @Valid @RequestBody DepartmentUpdateRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Department updated",
                departmentService.updateDepartment(id, request)));
    }

    @Operation(summary = "Change department active status")
    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<DepartmentResponse>> updateDepartmentStatus(
            @PathVariable Long id,
            @Valid @RequestBody DepartmentStatusRequest request) {
        return ResponseEntity.ok(ApiResponse.success(
                "Department status updated",
                departmentService.updateDepartmentStatus(id, request)));
    }
}
