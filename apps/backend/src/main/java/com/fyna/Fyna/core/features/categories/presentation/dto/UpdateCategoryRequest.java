package com.fyna.Fyna.core.features.categories.presentation.dto;

import jakarta.validation.constraints.Size;

public record UpdateCategoryRequest(
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        @Size(max = 50, message = "Ícone deve ter no máximo 50 caracteres")
        String icon,

        @Size(max = 7, message = "Cor deve ter no máximo 7 caracteres")
        String color,

        Boolean isActive,

        Integer displayOrder
) {
}
