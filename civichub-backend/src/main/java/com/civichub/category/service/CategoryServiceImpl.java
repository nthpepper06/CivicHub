package com.civichub.category.service;

import com.civichub.audit.service.AuditService;
import com.civichub.category.dto.request.CategoryCreateRequest;
import com.civichub.category.dto.request.CategoryStatusRequest;
import com.civichub.category.dto.request.CategoryUpdateRequest;
import com.civichub.category.dto.response.CategoryResponse;
import com.civichub.category.entity.Category;
import com.civichub.category.mapper.CategoryMapper;
import com.civichub.category.repository.CategoryRepository;
import com.civichub.common.PageResponse;
import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.common.exception.ResourceNotFoundException;
import jakarta.persistence.criteria.Predicate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CategoryServiceImpl implements CategoryService {

    private static final Sort DEFAULT_SORT = Sort.by(Sort.Direction.DESC, "createdAt");

    private final CategoryRepository categoryRepository;
    private final CategoryMapper categoryMapper;
    private final AuditService auditService;

    @Override
    @Transactional(readOnly = true)
    public List<CategoryResponse> getActiveCategories() {
        return categoryRepository.findAllByIsActiveTrueOrderByNameAsc()
                .stream()
                .map(categoryMapper::toResponse)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<CategoryResponse> getAdminCategories(int page, int size, String search, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, DEFAULT_SORT);
        Page<Category> categories = categoryRepository.findAll(buildSpecification(search, isActive), pageable);
        return toPageResponse(categories.map(categoryMapper::toResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public CategoryResponse getCategory(Long id) {
        return categoryMapper.toResponse(findCategory(id));
    }

    @Override
    @Transactional
    public CategoryResponse createCategory(CategoryCreateRequest request) {
        String name = normalizeRequiredName(request.getName());
        if (categoryRepository.existsByNameIgnoreCase(name)) {
            throw new ResourceAlreadyExistsException("Category name already exists");
        }

        Category category = Category.builder()
                .name(name)
                .description(normalizeOptional(request.getDescription()))
                .icon(normalizeOptional(request.getIcon()))
                .isActive(true)
                .build();
        try {
            Category savedCategory = categoryRepository.save(category);
            auditService.recordCategoryCreated(savedCategory);
            return categoryMapper.toResponse(savedCategory);
        } catch (DataIntegrityViolationException exception) {
            throw new ResourceAlreadyExistsException("Category name already exists");
        }
    }

    @Override
    @Transactional
    public CategoryResponse updateCategory(Long id, CategoryUpdateRequest request) {
        Category category = findCategory(id);
        String name = normalizeRequiredName(request.getName());
        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw new ResourceAlreadyExistsException("Category name already exists");
        }

        Map<String, Object> oldValues = categorySnapshot(category);
        category.setName(name);
        category.setDescription(normalizeOptional(request.getDescription()));
        category.setIcon(normalizeOptional(request.getIcon()));
        try {
            Category savedCategory = categoryRepository.save(category);
            auditService.recordCategoryUpdated(savedCategory, oldValues);
            return categoryMapper.toResponse(savedCategory);
        } catch (DataIntegrityViolationException exception) {
            throw new ResourceAlreadyExistsException("Category name already exists");
        }
    }

    @Override
    @Transactional
    public CategoryResponse updateCategoryStatus(Long id, CategoryStatusRequest request) {
        Category category = findCategory(id);
        boolean oldActive = category.isActive();
        category.setActive(request.getIsActive());
        Category savedCategory = categoryRepository.save(category);
        auditService.recordCategoryStatusChanged(savedCategory, oldActive, savedCategory.isActive());
        return categoryMapper.toResponse(savedCategory);
    }

    private Category findCategory(Long id) {
        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
    }

    private Specification<Category> buildSpecification(String search, Boolean isActive) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();
            String normalizedSearch = normalizeOptional(search);
            if (normalizedSearch != null) {
                predicates.add(criteriaBuilder.like(
                        criteriaBuilder.lower(root.get("name")),
                        "%" + normalizedSearch.toLowerCase() + "%"));
            }
            if (isActive != null) {
                predicates.add(criteriaBuilder.equal(root.get("isActive"), isActive));
            }
            return criteriaBuilder.and(predicates.toArray(Predicate[]::new));
        };
    }

    private PageResponse<CategoryResponse> toPageResponse(Page<CategoryResponse> page) {
        return PageResponse.<CategoryResponse>builder()
                .content(page.getContent())
                .page(page.getNumber())
                .size(page.getSize())
                .totalElements(page.getTotalElements())
                .totalPages(page.getTotalPages())
                .first(page.isFirst())
                .last(page.isLast())
                .build();
    }

    private String normalizeRequiredName(String name) {
        String normalized = name.trim();
        if (normalized.isBlank()) {
            throw new IllegalArgumentException("Name is required");
        }
        return normalized;
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    private Map<String, Object> categorySnapshot(Category category) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("name", category.getName());
        snapshot.put("description", category.getDescription());
        snapshot.put("icon", category.getIcon());
        snapshot.put("isActive", category.isActive());
        return snapshot;
    }
}
