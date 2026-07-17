package com.civichub.category.controller;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.civichub.category.dto.response.CategoryResponse;
import com.civichub.category.service.CategoryService;
import com.civichub.common.PageResponse;
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

@WebMvcTest({CategoryController.class, AdminCategoryController.class})
@Import({
        SecurityConfig.class,
        JwtAuthenticationFilter.class,
        RestAuthenticationEntryPoint.class,
        RestAccessDeniedHandler.class
})
class CategoryControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CategoryService categoryService;

    @MockBean
    private JwtService jwtService;

    @MockBean
    private CustomUserDetailsService customUserDetailsService;

    @Test
    void publicCategoriesShouldReturnOkWithoutAuthentication() throws Exception {
        when(categoryService.getActiveCategories()).thenReturn(List.of(categoryResponse()));

        mockMvc.perform(get("/api/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].name").value("Environment"));
    }

    @Test
    void adminCreateCategoryShouldReturnCreatedForAdmin() throws Exception {
        when(categoryService.createCategory(any())).thenReturn(categoryResponse());

        mockMvc.perform(post("/api/admin/categories")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Environment",
                                  "description": "Clean city",
                                  "icon": "leaf"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Environment"));
    }

    @Test
    void adminCreateCategoryShouldAcceptIconLongerThanOneHundredCharacters() throws Exception {
        when(categoryService.createCategory(any())).thenReturn(categoryResponse());
        String icon = "i".repeat(150);

        mockMvc.perform(post("/api/admin/categories")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Environment",
                                  "description": "Clean city",
                                  "icon": "%s"
                                }
                                """.formatted(icon)))
                .andExpect(status().isCreated());
    }

    @Test
    void adminCategoryEndpointShouldReturnForbiddenForNonAdmin() throws Exception {
        mockMvc.perform(post("/api/admin/categories")
                        .with(user("citizen@example.com").roles("CITIZEN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "name": "Environment"
                                }
                                """))
                .andExpect(status().isForbidden());
        verifyNoInteractions(categoryService);
    }

    @Test
    void invalidCategoryRequestShouldReturnBadRequest() throws Exception {
        mockMvc.perform(post("/api/admin/categories")
                        .with(user("admin@example.com").roles("ADMIN"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void adminListCategoriesShouldReturnPage() throws Exception {
        PageResponse<CategoryResponse> page = PageResponse.<CategoryResponse>builder()
                .content(List.of(categoryResponse()))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();
        when(categoryService.getAdminCategories(0, 10, null, null)).thenReturn(page);

        mockMvc.perform(get("/api/admin/categories")
                        .with(user("admin@example.com").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.page").value(0))
                .andExpect(jsonPath("$.data.content[0].name").value("Environment"));
    }

    private CategoryResponse categoryResponse() {
        return CategoryResponse.builder()
                .id(1L)
                .name("Environment")
                .description("Clean city")
                .icon("leaf")
                .isActive(true)
                .build();
    }
}
