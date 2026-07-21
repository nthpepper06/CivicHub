package com.civichub.auth.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.auth.dto.request.ProfileUpdateRequest;
import com.civichub.auth.dto.response.AuthResponse;
import com.civichub.auth.dto.response.CurrentUserResponse;
import com.civichub.auth.service.AuthService;
import com.civichub.common.enums.UserRole;
import com.civichub.common.enums.UserStatus;
import com.civichub.security.CustomUserDetailsService;
import com.civichub.security.JwtAuthenticationFilter;
import com.civichub.security.JwtService;
import com.civichub.security.RestAccessDeniedHandler;
import com.civichub.security.RestAuthenticationEntryPoint;
import com.civichub.security.SecurityConfig;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(AuthController.class)
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private AuthService authService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void registerShouldReturnCreated() throws Exception {
        when(authService.register(any())).thenReturn(authResponse());

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "Nguyen Van A",
                                  "email": "citizen@example.com",
                                  "password": "strongPassword",
                                  "phone": "0909000000"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.accessToken").value("jwt-token"));
    }

    @Test
    void loginShouldReturnOk() throws Exception {
        when(authService.login(any())).thenReturn(authResponse());

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "citizen@example.com",
                                  "password": "strongPassword"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.tokenType").value("Bearer"));
    }

    @Test
    void invalidRegisterRequestShouldReturnBadRequest() throws Exception {
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void meShouldRequireAuthentication() throws Exception {
        mockMvc.perform(get("/api/auth/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
        verifyNoInteractions(authService);
    }

    @Test
    void authenticatedUserCanUpdateOwnProfileWithoutMassAssignment() throws Exception {
        when(authService.updateCurrentUser(any())).thenReturn(CurrentUserResponse.builder()
                .id(1L)
                .fullName("Nguyen Van B")
                .email("citizen@example.com")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build());

        mockMvc.perform(patch("/api/auth/me")
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
                                .user("citizen@example.com")
                                .roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "Nguyen Van B",
                                  "phone": "0909000001",
                                  "avatar": "https://example.com/avatar.png",
                                  "role": "ADMIN",
                                  "password": "hacked"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value("Nguyen Van B"))
                .andExpect(jsonPath("$.data.password").doesNotExist());

        ArgumentCaptor<ProfileUpdateRequest> requestCaptor = ArgumentCaptor.forClass(ProfileUpdateRequest.class);
        verify(authService).updateCurrentUser(requestCaptor.capture());
        assertThat(requestCaptor.getValue().getFullName()).isEqualTo("Nguyen Van B");
        assertThat(requestCaptor.getValue().getPhone()).isEqualTo("0909000001");
        assertThat(requestCaptor.getValue().getAvatar()).isEqualTo("https://example.com/avatar.png");
    }

    @Test
    void profileUpdateShouldRequireAuthentication() throws Exception {
        mockMvc.perform(patch("/api/auth/me")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"fullName\":\"Nguyen Van B\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void authenticatedUserCanChangePassword() throws Exception {
        mockMvc.perform(patch("/api/auth/change-password")
                        .with(org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors
                                .user("citizen@example.com")
                                .roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "old-password",
                                  "newPassword": "new-password"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").doesNotExist());

        verify(authService).changePassword(any());
    }

    @Test
    void changePasswordShouldRequireAuthentication() throws Exception {
        mockMvc.perform(patch("/api/auth/change-password")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "currentPassword": "old-password",
                                  "newPassword": "new-password"
                                }
                                """))
                .andExpect(status().isUnauthorized());
    }

    private AuthResponse authResponse() {
        CurrentUserResponse user = CurrentUserResponse.builder()
                .id(1L)
                .fullName("Nguyen Van A")
                .email("citizen@example.com")
                .role(UserRole.CITIZEN)
                .status(UserStatus.ACTIVE)
                .isActive(true)
                .build();
        return AuthResponse.builder()
                .accessToken("jwt-token")
                .tokenType("Bearer")
                .expiresIn(86400L)
                .user(user)
                .build();
    }
}
