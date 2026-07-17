package com.civichub.department.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.department.dto.response.DepartmentResponse;
import com.civichub.department.service.DepartmentService;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdminDepartmentController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class DepartmentControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private DepartmentService departmentService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanCreateDepartment() throws Exception {
        when(departmentService.createDepartment(any())).thenReturn(departmentResponse());

        mockMvc.perform(post("/api/admin/departments")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Urban Services",
                                  "description": "Handles issues"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Urban Services"));
    }

    @Test
    void adminCanListDepartments() throws Exception {
        PageResponse<DepartmentResponse> page = PageResponse.<DepartmentResponse>builder()
                .content(List.of(departmentResponse()))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();
        when(departmentService.getDepartments(0, 10, null, null)).thenReturn(page);

        mockMvc.perform(get("/api/admin/departments")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].name").value("Urban Services"));
    }

    @Test
    void adminCanUpdateDepartmentStatus() throws Exception {
        DepartmentResponse inactive = DepartmentResponse.builder()
                .id(1L)
                .name("Urban Services")
                .isActive(false)
                .build();
        when(departmentService.updateDepartmentStatus(any(), any())).thenReturn(inactive);

        mockMvc.perform(patch("/api/admin/departments/1/status")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "isActive": false
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isActive").value(false));
    }

    @Test
    void citizenShouldReceiveForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/departments")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
        verifyNoInteractions(departmentService);
    }

    @Test
    void unauthenticatedUserShouldReceiveUnauthorized() throws Exception {
        mockMvc.perform(get("/api/admin/departments"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
        verifyNoInteractions(departmentService);
    }

    @Test
    void invalidDepartmentRequestShouldReturnBadRequest() throws Exception {
        mockMvc.perform(post("/api/admin/departments")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    private DepartmentResponse departmentResponse() {
        return DepartmentResponse.builder()
                .id(1L)
                .name("Urban Services")
                .description("Handles issues")
                .isActive(true)
                .build();
    }
}
