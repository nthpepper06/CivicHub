package com.civichub.category.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.category.dto.request.CategoryCreateRequest;
import com.civichub.category.dto.request.CategoryStatusRequest;
import com.civichub.category.dto.request.CategoryUpdateRequest;
import com.civichub.category.dto.response.CategoryResponse;
import com.civichub.category.entity.Category;
import com.civichub.category.mapper.CategoryMapper;
import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.common.exception.ResourceNotFoundException;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class CategoryServiceImplTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private CategoryMapper categoryMapper;

    private CategoryServiceImpl categoryService;

    @BeforeEach
    void setUp() {
        categoryService = new CategoryServiceImpl(categoryRepository, categoryMapper);
    }

    @Test
    void publicListingShouldUseActiveCategoriesOnly() {
        Category active = category(1L, "Environment", true);
        CategoryResponse response = response(1L, "Environment", true);

        when(categoryRepository.findAllByIsActiveTrueOrderByNameAsc()).thenReturn(List.of(active));
        when(categoryMapper.toResponse(active)).thenReturn(response);

        List<CategoryResponse> result = categoryService.getActiveCategories();

        verify(categoryRepository).findAllByIsActiveTrueOrderByNameAsc();
        assertThat(result).containsExactly(response);
    }

    @Test
    void createCategoryShouldNormalizeNameAndOptionalFields() {
        CategoryCreateRequest request = new CategoryCreateRequest("  Environment  ", "  Clean city  ", "  leaf  ");

        when(categoryRepository.existsByNameIgnoreCase("Environment")).thenReturn(false);
        when(categoryRepository.save(any(Category.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(categoryMapper.toResponse(any(Category.class))).thenReturn(response(1L, "Environment", true));

        categoryService.createCategory(request);

        ArgumentCaptor<Category> captor = ArgumentCaptor.forClass(Category.class);
        verify(categoryRepository).save(captor.capture());
        Category saved = captor.getValue();
        assertThat(saved.getName()).isEqualTo("Environment");
        assertThat(saved.getDescription()).isEqualTo("Clean city");
        assertThat(saved.getIcon()).isEqualTo("leaf");
        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void createCategoryShouldRejectDuplicateName() {
        CategoryCreateRequest request = new CategoryCreateRequest("Environment", null, null);
        when(categoryRepository.existsByNameIgnoreCase("Environment")).thenReturn(true);

        assertThatThrownBy(() -> categoryService.createCategory(request))
                .isInstanceOf(ResourceAlreadyExistsException.class);
        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    void updateCategoryShouldRejectAnotherCategoryDuplicateName() {
        CategoryUpdateRequest request = new CategoryUpdateRequest("Environment", null, null);
        when(categoryRepository.findById(2L)).thenReturn(Optional.of(category(2L, "Road", true)));
        when(categoryRepository.existsByNameIgnoreCaseAndIdNot("Environment", 2L)).thenReturn(true);

        assertThatThrownBy(() -> categoryService.updateCategory(2L, request))
                .isInstanceOf(ResourceAlreadyExistsException.class);
        verify(categoryRepository, never()).save(any(Category.class));
    }

    @Test
    void statusUpdateShouldChangeOnlyIsActive() {
        Category category = category(1L, "Environment", true);
        CategoryStatusRequest request = new CategoryStatusRequest(false);

        when(categoryRepository.findById(1L)).thenReturn(Optional.of(category));
        when(categoryRepository.save(category)).thenReturn(category);
        when(categoryMapper.toResponse(category)).thenReturn(response(1L, "Environment", false));

        categoryService.updateCategoryStatus(1L, request);

        assertThat(category.getName()).isEqualTo("Environment");
        assertThat(category.isActive()).isFalse();
    }

    @Test
    void missingCategoryShouldThrowNotFound() {
        when(categoryRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> categoryService.getCategory(404L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    private Category category(Long id, String name, boolean active) {
        return Category.builder()
                .id(id)
                .name(name)
                .isActive(active)
                .build();
    }

    private CategoryResponse response(Long id, String name, boolean active) {
        return CategoryResponse.builder()
                .id(id)
                .name(name)
                .isActive(active)
                .build();
    }
}
