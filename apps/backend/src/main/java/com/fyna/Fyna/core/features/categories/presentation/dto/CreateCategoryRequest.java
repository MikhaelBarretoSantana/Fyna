package com.fyna.Fyna.core.features.categories.presentation.dto;

import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CreateCategoryRequest(
        @NotBlank(message = "Nome é obrigatório")
        @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
        String name,

        @Size(max = 50, message = "Ícone deve ter no máximo 50 caracteres")
        String icon,

        @Size(max = 7, message = "Cor deve ter no máximo 7 caracteres")
        String color,

        @NotNull(message = "Tipo é obrigatório")
        CategoriesTypes type,

        UUID parentId,

        Integer displayOrder
) {
}
