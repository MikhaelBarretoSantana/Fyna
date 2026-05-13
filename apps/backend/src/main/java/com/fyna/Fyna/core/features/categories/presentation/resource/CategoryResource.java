package com.fyna.Fyna.core.features.categories.presentation.resource;

import java.util.List;
import java.util.UUID;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.fyna.Fyna.core.features.categories.domain.service.CategoryService;
import com.fyna.Fyna.core.features.categories.presentation.dto.CategoryResponse;
import com.fyna.Fyna.core.features.categories.presentation.dto.CreateCategoryRequest;
import com.fyna.Fyna.core.features.categories.presentation.dto.UpdateCategoryRequest;
import com.fyna.Fyna.core.security.SecurityUtils;
import com.fyna.Fyna.core.shared.dto.ApiResponse;
import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/categories")
public class CategoryResource {

    private final CategoryService categoryService;
    private final SecurityUtils securityUtils;

    public CategoryResource(CategoryService categoryService, SecurityUtils securityUtils) {
        this.categoryService = categoryService;
        this.securityUtils = securityUtils;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getAllCategories(
            @RequestParam(required = false) CategoriesTypes type) {
        UUID userId = securityUtils.getCurrentUserId();
        List<CategoryResponse> categories;

        if (type != null) {
            categories = categoryService.getCategoriesByType(userId, type);
        } else {
            categories = categoryService.getAllCategories(userId);
        }

        return ResponseEntity.ok(ApiResponse.ok(categories));
    }

    @GetMapping("/system")
    public ResponseEntity<ApiResponse<List<CategoryResponse>>> getSystemCategories() {
        List<CategoryResponse> categories = categoryService.getSystemCategories();
        return ResponseEntity.ok(ApiResponse.ok(categories));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CategoryResponse>> getCategory(@PathVariable UUID id) {
        CategoryResponse category = categoryService.getCategory(id);
        return ResponseEntity.ok(ApiResponse.ok(category));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CategoryResponse>> createCategory(
            @Valid @RequestBody CreateCategoryRequest request) {
        CategoryResponse category = categoryService.createCategory(securityUtils.getCurrentUserId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.created(category));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CategoryResponse>> updateCategory(@PathVariable UUID id,
            @Valid @RequestBody UpdateCategoryRequest request) {
        CategoryResponse category = categoryService.updateCategory(id, securityUtils.getCurrentUserId(), request);
        return ResponseEntity.ok(ApiResponse.ok(category));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable UUID id) {
        categoryService.deleteCategory(id, securityUtils.getCurrentUserId());
        return ResponseEntity.noContent().build();
    }
}
