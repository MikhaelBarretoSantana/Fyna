package com.fyna.Fyna.core.features.ai.presentation.dto;

import java.util.UUID;

import jakarta.validation.constraints.NotNull;

public record ConfirmClassificationRequest(
        @NotNull(message = "ID da categoria confirmada é obrigatório")
        UUID confirmedCategoryId
) {
}
