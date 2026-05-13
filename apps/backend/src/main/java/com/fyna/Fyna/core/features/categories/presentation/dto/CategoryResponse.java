package com.fyna.Fyna.core.features.categories.presentation.dto;

import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

public record CategoryResponse(
        UUID id,
        UUID parentId,
        String name,
        String icon,
        String color,
        CategoriesTypes type,
        boolean isSystem,
        boolean isActive,
        int displayOrder
) {
    public static CategoryResponse from(Categories category) {
        return new CategoryResponse(
                category.getId(),
                category.getParent() != null ? category.getParent().getId() : null,
                category.getName(),
                category.getIcon(),
                category.getColor(),
                category.getType(),
                category.getIsSystem(),
                category.getIsActive(),
                category.getDisplayOrder()
        );
    }
}
