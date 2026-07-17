package com.civichub.department.service;

import com.civichub.audit.service.AuditService;
import com.civichub.common.PageResponse;
import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.dto.request.DepartmentCreateRequest;
import com.civichub.department.dto.request.DepartmentStatusRequest;
import com.civichub.department.dto.request.DepartmentUpdateRequest;
import com.civichub.department.dto.response.DepartmentResponse;
import com.civichub.department.entity.Department;
import com.civichub.department.mapper.DepartmentMapper;
import com.civichub.department.repository.DepartmentRepository;
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
public class DepartmentServiceImpl implements DepartmentService {

    private static final Sort DEFAULT_SORT = Sort.by(Sort.Direction.DESC, "createdAt");

    private final DepartmentRepository departmentRepository;
    private final DepartmentMapper departmentMapper;
    private final AuditService auditService;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<DepartmentResponse> getDepartments(int page, int size, String search, Boolean isActive) {
        Pageable pageable = PageRequest.of(page, size, DEFAULT_SORT);
        Page<Department> departments = departmentRepository.findAll(buildSpecification(search, isActive), pageable);
        return toPageResponse(departments.map(departmentMapper::toResponse));
    }

    @Override
    @Transactional(readOnly = true)
    public DepartmentResponse getDepartment(Long id) {
        return departmentMapper.toResponse(findDepartment(id));
    }

    @Override
    @Transactional
    public DepartmentResponse createDepartment(DepartmentCreateRequest request) {
        String name = normalizeRequiredName(request.getName());
        if (departmentRepository.existsByNameIgnoreCase(name)) {
            throw new ResourceAlreadyExistsException("Department name already exists");
        }

        Department department = Department.builder()
                .name(name)
                .description(normalizeOptional(request.getDescription()))
                .isActive(true)
                .build();
        try {
            Department savedDepartment = departmentRepository.save(department);
            auditService.recordDepartmentCreated(savedDepartment);
            return departmentMapper.toResponse(savedDepartment);
        } catch (DataIntegrityViolationException exception) {
            throw new ResourceAlreadyExistsException("Department name already exists");
        }
    }

    @Override
    @Transactional
    public DepartmentResponse updateDepartment(Long id, DepartmentUpdateRequest request) {
        Department department = findDepartment(id);
        String name = normalizeRequiredName(request.getName());
        if (departmentRepository.existsByNameIgnoreCaseAndIdNot(name, id)) {
            throw new ResourceAlreadyExistsException("Department name already exists");
        }

        Map<String, Object> oldValues = departmentSnapshot(department);
        department.setName(name);
        department.setDescription(normalizeOptional(request.getDescription()));
        try {
            Department savedDepartment = departmentRepository.save(department);
            auditService.recordDepartmentUpdated(savedDepartment, oldValues);
            return departmentMapper.toResponse(savedDepartment);
        } catch (DataIntegrityViolationException exception) {
            throw new ResourceAlreadyExistsException("Department name already exists");
        }
    }

    @Override
    @Transactional
    public DepartmentResponse updateDepartmentStatus(Long id, DepartmentStatusRequest request) {
        Department department = findDepartment(id);
        boolean oldActive = department.isActive();
        department.setActive(request.getIsActive());
        Department savedDepartment = departmentRepository.save(department);
        auditService.recordDepartmentStatusChanged(savedDepartment, oldActive, savedDepartment.isActive());
        return departmentMapper.toResponse(savedDepartment);
    }

    private Department findDepartment(Long id) {
        return departmentRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Department not found"));
    }

    private Specification<Department> buildSpecification(String search, Boolean isActive) {
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

    private PageResponse<DepartmentResponse> toPageResponse(Page<DepartmentResponse> page) {
        return PageResponse.<DepartmentResponse>builder()
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

    private Map<String, Object> departmentSnapshot(Department department) {
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("name", department.getName());
        snapshot.put("description", department.getDescription());
        snapshot.put("isActive", department.isActive());
        return snapshot;
    }
}
