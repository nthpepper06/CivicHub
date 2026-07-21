package com.civichub.user.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.common.PageResponse;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import com.civichub.user.dto.response.AdminUserResponse;
import com.civichub.user.service.UserService;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AdminUserController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AdminUserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private UserService userService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void adminCanListUsers() throws Exception {
        when(userService.getUsers(0, 10, null, null, null, null, null, null, null))
                .thenReturn(PageResponse.<AdminUserResponse>builder()
                        .content(List.of(adminUser()))
                        .page(0)
                        .size(10)
                        .build());

        mockMvc.perform(get("/api/admin/users")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content[0].email").value("admin@example.com"))
                .andExpect(jsonPath("$.data.content[0].password").doesNotExist());
    }

    @Test
    void adminCanViewUserDetail() throws Exception {
        when(userService.getUser(1L)).thenReturn(adminUser());

        mockMvc.perform(get("/api/admin/users/1")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.password").doesNotExist());
    }

    @Test
    void adminCanUpdateUserStatus() throws Exception {
        when(userService.updateUserStatus(any(), any()))
                .thenReturn(AdminUserResponse.builder().id(1L).isActive(false).status(UserStatus.INACTIVE).build());

        mockMvc.perform(patch("/api/admin/users/1/status")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"isActive\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isActive").value(false))
                .andExpect(jsonPath("$.data.status").value("INACTIVE"));
    }

    @Test
    void adminCanAssignDepartment() throws Exception {
        when(userService.assignUserDepartment(any(), any()))
                .thenReturn(AdminUserResponse.builder().id(1L).departmentId(5L).build());

        mockMvc.perform(patch("/api/admin/users/1/department")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"departmentId\":5}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.departmentId").value(5));
    }

    @Test
    void adminCanExportUsers() throws Exception {
        when(userService.exportUsersCsv(null, null, null, null, null, null, null))
                .thenReturn("\ufeffID,Full Name\n1,'=SUM(A1:A2)");

        mockMvc.perform(get("/api/admin/users/export")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith("text/csv"))
                .andExpect(header().string(
                        HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"civichub-users.csv\""))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("'=SUM")));
    }

    @Test
    void unauthenticatedUserReceivesUnauthorized() throws Exception {
        mockMvc.perform(get("/api/admin/users"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void citizenReceivesForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/users")
                        .with(user("citizen@example.com").roles("CITIZEN")))
                .andExpect(status().isForbidden());
    }

    @Test
    void staffReceivesForbidden() throws Exception {
        mockMvc.perform(get("/api/admin/users")
                        .with(user("staff@example.com").roles("STAFF")))
                .andExpect(status().isForbidden());
    }

    @Test
    void invalidDepartmentRequestReturnsBadRequest() throws Exception {
        mockMvc.perform(patch("/api/admin/users/1/department")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest());
    }

    private AdminUserResponse adminUser() {
        return AdminUserResponse.builder()
                .id(1L)
                .fullName("Admin")
                .email("admin@example.com")
                .role(UserRole.ADMIN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
    }
}
