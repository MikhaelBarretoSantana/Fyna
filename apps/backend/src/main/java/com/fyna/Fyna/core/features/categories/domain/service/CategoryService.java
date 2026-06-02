package com.fyna.Fyna.core.features.categories.domain.service;

import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.data.repository.BudgetRepository;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
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
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;

    public CategoryService(CategoryRepository categoryRepository, UserRepository userRepository,
            TransactionRepository transactionRepository, BudgetRepository budgetRepository) {
        this.categoryRepository = categoryRepository;
        this.userRepository = userRepository;
        this.transactionRepository = transactionRepository;
        this.budgetRepository = budgetRepository;
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
    @Cacheable(value = "system-categories")
    public List<CategoryResponse> getSystemCategories() {
        return categoryRepository.findByUserIsNullAndIsSystemTrueAndIsActiveTrue().stream()
                .map(CategoryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    @Cacheable(value = "category-by-type", key = "#userId.toString() + '::' + #type.name()")
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
    public CategoryResponse getCategory(UUID categoryId, UUID userId) {
        Categories category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));
        if (!isVisibleTo(category, userId)) {
            throw new ResourceNotFoundException("Category", "id", categoryId);
        }
        return CategoryResponse.from(category);
    }

    @Transactional
    @CacheEvict(value = "category-by-type", allEntries = true)
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
            if (!isVisibleTo(parent, userId)) {
                throw new BadRequestException("Categoria pai não pertence a este usuário");
            }
            category.setParent(parent);
        }

        category = categoryRepository.save(category);
        return CategoryResponse.from(category);
    }

    /** Categoria é visível se for do sistema ou pertencer ao próprio usuário. */
    private boolean isVisibleTo(Categories category, UUID userId) {
        if (Boolean.TRUE.equals(category.getIsSystem())) return true;
        return category.getUser() != null && category.getUser().getId().equals(userId);
    }

    @Transactional
    @CacheEvict(value = "category-by-type", allEntries = true)
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
    @Caching(evict = {
            @CacheEvict(value = "category-by-type", allEntries = true),
            @CacheEvict(value = "system-categories", allEntries = true)
    })
    public void deleteCategory(UUID categoryId, UUID userId) {
        Categories category = categoryRepository.findById(categoryId)
                .orElseThrow(() -> new ResourceNotFoundException("Category", "id", categoryId));

        if (category.getIsSystem()) {
            throw new BadRequestException("Categorias do sistema não podem ser excluídas");
        }

        if (category.getUser() == null || !category.getUser().getId().equals(userId)) {
            throw new BadRequestException("Você não tem permissão para excluir esta categoria");
        }

        // Bloquear delete se ainda há vínculos: o usuário precisa remover/reclassificar
        // as transações e desativar/realocar os budgets vinculados antes.
        long txCount = transactionRepository.countByCategoriesId(categoryId);
        if (txCount > 0) {
            throw new BadRequestException(
                    "Categoria possui " + txCount + " transação(ões) vinculada(s). "
                    + "Reclassifique-as antes de excluir.");
        }
        long budgetCount = budgetRepository.countByCategoryIdAndIsActiveTrue(categoryId);
        if (budgetCount > 0) {
            throw new BadRequestException(
                    "Categoria possui " + budgetCount + " orçamento(s) ativo(s) vinculado(s). "
                    + "Desative-os antes de excluir.");
        }

        category.setIsActive(false);
        categoryRepository.save(category);
    }
}
