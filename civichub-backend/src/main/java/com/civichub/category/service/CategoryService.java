package com.civichub.category.service;

import com.civichub.category.dto.request.CategoryCreateRequest;
import com.civichub.category.dto.request.CategoryStatusRequest;
import com.civichub.category.dto.request.CategoryUpdateRequest;
import com.civichub.category.dto.response.CategoryResponse;
import com.civichub.common.PageResponse;
import java.util.List;

public interface CategoryService {

    List<CategoryResponse> getActiveCategories();

    PageResponse<CategoryResponse> getAdminCategories(int page, int size, String search, Boolean isActive);

    CategoryResponse getCategory(Long id);

    CategoryResponse createCategory(CategoryCreateRequest request);

    CategoryResponse updateCategory(Long id, CategoryUpdateRequest request);

    CategoryResponse updateCategoryStatus(Long id, CategoryStatusRequest request);
}
