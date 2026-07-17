package com.civichub.department.service;

import com.civichub.common.PageResponse;
import com.civichub.department.dto.request.DepartmentCreateRequest;
import com.civichub.department.dto.request.DepartmentStatusRequest;
import com.civichub.department.dto.request.DepartmentUpdateRequest;
import com.civichub.department.dto.response.DepartmentResponse;

public interface DepartmentService {

    PageResponse<DepartmentResponse> getDepartments(int page, int size, String search, Boolean isActive);

    DepartmentResponse getDepartment(Long id);

    DepartmentResponse createDepartment(DepartmentCreateRequest request);

    DepartmentResponse updateDepartment(Long id, DepartmentUpdateRequest request);

    DepartmentResponse updateDepartmentStatus(Long id, DepartmentStatusRequest request);
}
