package com.civichub.auth.mapper;

import com.civichub.auth.dto.response.CurrentUserResponse;
import com.civichub.user.entity.User;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AuthMapper {

    @Mapping(source = "department.id", target = "departmentId")
    @Mapping(source = "department.name", target = "departmentName")
    @Mapping(target = "isActive", expression = "java(user.isActive())")
    CurrentUserResponse toCurrentUserResponse(User user);
}
