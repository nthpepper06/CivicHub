package com.civichub.department.mapper;

import com.civichub.department.dto.response.DepartmentResponse;
import com.civichub.department.entity.Department;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface DepartmentMapper {

    @Mapping(target = "isActive", expression = "java(department.isActive())")
    DepartmentResponse toResponse(Department department);
}
