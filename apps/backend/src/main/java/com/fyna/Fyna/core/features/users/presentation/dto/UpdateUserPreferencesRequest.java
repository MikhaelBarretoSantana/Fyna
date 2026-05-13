package com.fyna.Fyna.core.features.users.presentation.dto;

import com.fyna.Fyna.core.shared.enums.SystemThemes;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

public record UpdateUserPreferencesRequest(
        @Size(min = 3, max = 3, message = "Moeda deve ter 3 caracteres (ISO 4217)")
        String currency,

        @Size(max = 10, message = "Locale deve ter no máximo 10 caracteres")
        String locale,

        @Size(max = 50, message = "Timezone deve ter no máximo 50 caracteres")
        String timezone,

        SystemThemes theme,

        Boolean pushNotifications,

        Boolean emailNotifications,

        Boolean budgetAlerts,

        Boolean weeklySummary,

        Boolean aiSuggestions,

        @Min(value = 0, message = "Primeiro dia da semana deve ser entre 0 e 6")
        @Max(value = 6, message = "Primeiro dia da semana deve ser entre 0 e 6")
        Integer firstDayOfWeek
) {
}
