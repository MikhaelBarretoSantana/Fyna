package com.fyna.Fyna.core.features.categories.domain.service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.categories.presentation.dto.CategoryResponse;
import com.fyna.Fyna.core.features.categories.presentation.dto.CreateCategoryRequest;
import com.fyna.Fyna.core.features.categories.presentation.dto.UpdateCategoryRequest;
import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.domain.User;
import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final UserRepository userRepository;

    public CategoryService(CategoryRepository categoryRepository, UserRepository userRepository) {
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> getAllCategories(UUID userId) {
        List<Categories> systemCategories = categoryRepository.findByUserIsNullAndIsSystemTrueAndIsActiveTrue();
        List<Categories> userCategories = categoryRepository.findByUserIdAndIsActiveTrue(userId);

        return Stream.concat(systemCategories.stream(), userCategories.stream())
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> getSystemCategories() {
        return categoryRepository.findByUserIsNullAndIsSystemTrueAndIsActiveTrue().stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> getCategoriesByType(UUID userId, CategoriesTypes type) {
        List<Categories> systemByType = categoryRepository.findByTypeAndIsActiveTrue(type).stream()
                .filter(c -> c.getUser() == null)
                .toList();
        List<Categories> userByType = categoryRepository.findByUserIdAndTypeAndIsActiveTrue(userId, type);

        return Stream.concat(systemByType.stream(), userByType.stream())
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public CategoryResponse getCategory(UUID categoryId) {
        Categories category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        return CategoryResponse.from(category);
    }

    @Transactional
    public CategoryResponse createCategory(UUID userId, CreateCategoryRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        Categories category = new Categories();
        category.setUser(user);
        category.setName(request.name());
        category.setIcon(request.icon());
        category.setColor(request.color());
        category.setType(request.type());
        category.setIsSystem(false);
        category.setIsActive(true);
        category.setDisplayOrder(request.displayOrder() != null ? request.displayOrder() : 0);

        if (request.parentId() != null) {
            Categories parent = categoryRepository.findById(request.parentId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category", "id", request.parentId()));
            category.setParent(parent);
        }

        category = categoryRepository.save(category);
        return CategoryResponse.from(category);
    }

    @Transactional
    public CategoryResponse updateCategory(UUID categoryId, UUID userId, UpdateCategoryRequest request) {
        Categories category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));

        if (category.getIsSystem()) {
            throw new BadRequestException("Categorias do sistema não podem ser editadas");
        }

        if (category.getUser() == null || !category.getUser().getId().equals(userId)) {
            throw new BadRequestException("Você não tem permissão para editar esta categoria");
        }

        if (request.name() != null) category.setName(request.name());
        if (request.icon() != null) category.setIcon(request.icon());
        if (request.color() != null) category.setColor(request.color());
        if (request.isActive() != null) category.setIsActive(request.isActive());
        if (request.displayOrder() != null) category.setDisplayOrder(request.displayOrder());

        category = categoryRepository.save(category);
        return CategoryResponse.from(category);
    }

    @Transactional
    public void deleteCategory(UUID categoryId, UUID userId) {
        Categories category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));

        if (category.getIsSystem()) {
            throw new BadRequestException("Categorias do sistema não podem ser excluídas");
        }

        if (category.getUser() == null || !category.getUser().getId().equals(userId)) {
            throw new BadRequestException("Você não tem permissão para excluir esta categoria");
        }

        category.setIsActive(false);
        categoryRepository.save(category);
    }
}
