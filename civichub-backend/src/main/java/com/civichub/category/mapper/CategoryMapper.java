package com.civichub.category.mapper;

import com.civichub.category.dto.response.CategoryResponse;
import com.civichub.category.entity.Category;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface CategoryMapper {

    @Mapping(target = "isActive", expression = "java(category.isActive())")
    CategoryResponse toResponse(Category category);
}
