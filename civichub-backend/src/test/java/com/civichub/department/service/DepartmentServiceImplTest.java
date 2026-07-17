package com.civichub.department.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.civichub.common.exception.ResourceAlreadyExistsException;
import com.civichub.common.exception.ResourceNotFoundException;
import com.civichub.department.dto.request.DepartmentCreateRequest;
import com.civichub.department.dto.request.DepartmentStatusRequest;
import com.civichub.department.dto.request.DepartmentUpdateRequest;
import com.civichub.department.dto.response.DepartmentResponse;
import com.civichub.department.entity.Department;
import com.civichub.department.mapper.DepartmentMapper;
import com.civichub.department.repository.DepartmentRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class DepartmentServiceImplTest {

    @Mock
    private DepartmentRepository departmentRepository;

    @Mock
    private DepartmentMapper departmentMapper;

    private DepartmentServiceImpl departmentService;

    @BeforeEach
    void setUp() {
        departmentService = new DepartmentServiceImpl(departmentRepository, departmentMapper);
    }

    @Test
    void createDepartmentShouldNormalizeName() {
        DepartmentCreateRequest request = new DepartmentCreateRequest("  Urban Services  ", "  Handles issues  ");

        when(departmentRepository.existsByNameIgnoreCase("Urban Services")).thenReturn(false);
        when(departmentRepository.save(any(Department.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(departmentMapper.toResponse(any(Department.class))).thenReturn(response(1L, "Urban Services", true));

        departmentService.createDepartment(request);

        ArgumentCaptor<Department> captor = ArgumentCaptor.forClass(Department.class);
        verify(departmentRepository).save(captor.capture());
        Department saved = captor.getValue();
        assertThat(saved.getName()).isEqualTo("Urban Services");
        assertThat(saved.getDescription()).isEqualTo("Handles issues");
        assertThat(saved.isActive()).isTrue();
    }

    @Test
    void createDepartmentShouldRejectDuplicateName() {
        DepartmentCreateRequest request = new DepartmentCreateRequest("Urban Services", null);
        when(departmentRepository.existsByNameIgnoreCase("Urban Services")).thenReturn(true);

        assertThatThrownBy(() -> departmentService.createDepartment(request))
                .isInstanceOf(ResourceAlreadyExistsException.class);
        verify(departmentRepository, never()).save(any(Department.class));
    }

    @Test
    void updateDepartmentShouldPreserveIsActive() {
        Department department = department(1L, "Old Name", false);
        DepartmentUpdateRequest request = new DepartmentUpdateRequest("  New Name  ", null);

        when(departmentRepository.findById(1L)).thenReturn(Optional.of(department));
        when(departmentRepository.existsByNameIgnoreCaseAndIdNot("New Name", 1L)).thenReturn(false);
        when(departmentRepository.save(department)).thenReturn(department);
        when(departmentMapper.toResponse(department)).thenReturn(response(1L, "New Name", false));

        departmentService.updateDepartment(1L, request);

        assertThat(department.getName()).isEqualTo("New Name");
        assertThat(department.isActive()).isFalse();
    }

    @Test
    void statusUpdateShouldWork() {
        Department department = department(1L, "Urban Services", true);
        DepartmentStatusRequest request = new DepartmentStatusRequest(false);

        when(departmentRepository.findById(1L)).thenReturn(Optional.of(department));
        when(departmentRepository.save(department)).thenReturn(department);
        when(departmentMapper.toResponse(department)).thenReturn(response(1L, "Urban Services", false));

        departmentService.updateDepartmentStatus(1L, request);

        assertThat(department.isActive()).isFalse();
    }

    @Test
    void missingDepartmentShouldThrowNotFound() {
        when(departmentRepository.findById(404L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> departmentService.getDepartment(404L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    private Department department(Long id, String name, boolean active) {
        return Department.builder()
                .id(id)
                .name(name)
                .isActive(active)
                .build();
    }

    private DepartmentResponse response(Long id, String name, boolean active) {
        return DepartmentResponse.builder()
                .id(id)
                .name(name)
                .isActive(active)
                .build();
    }
}
