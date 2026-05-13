package com.fyna.Fyna.core.features.users.presentation.dto;

import com.fyna.Fyna.core.shared.domain.UserPreferences;
import com.fyna.Fyna.core.shared.enums.SystemThemes;

import java.util.UUID;

public record UserPreferencesResponse(
        UUID id,
        String currency,
        String locale,
        String timeZone,
        SystemThemes theme,
        boolean pushNotifications,
        boolean emailNotifications,
        boolean budgetAlerts,
        boolean weeklySummary,
        boolean aiSuggestions,
        int firstDayOfWeek
) {
    public static UserPreferencesResponse from(UserPreferences prefs) {
        return new UserPreferencesResponse(
                prefs.getId(),
                prefs.getCurrency(),
                prefs.getLocale(),
                prefs.getTimeZone(),
                prefs.getTheme(),
                prefs.isPushNotifications(),
                prefs.isEmailNotifications(),
                prefs.isBudgetAlerts(),
                prefs.isWeeklySummary(),
                prefs.isAiSuggestions(),
                prefs.getFirstDayOfWeek()
        );
    }
}
