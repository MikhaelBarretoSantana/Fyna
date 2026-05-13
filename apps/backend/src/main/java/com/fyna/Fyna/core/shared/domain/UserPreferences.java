package com.fyna.Fyna.core.shared.domain;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fyna.Fyna.core.shared.enums.SystemThemes;

import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import lombok.Builder;

@Builder
@Entity
@Table(name = "user_preferences", indexes = {
    @Index(name = "idx_user_preferences_user_id", columnList = "user_id")
})
public class UserPreferences extends AbstractAuditingEntity<UUID> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties(value = "userPreferences", allowSetters = true)
    private User user;

    @Builder.Default
    @Column(name = "currency", length = 3, nullable = false)
    private String currency = "BRL";

    @Builder.Default
    @Column(name = "locale", length = 10, nullable = false)
    private String locale = "pt-BR";

    @Builder.Default
    @Column(name = "timezone", length = 50, nullable = false)
    private String timeZone = "America/Sao_Paulo";

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(name = "theme", nullable = false)
    private SystemThemes theme = SystemThemes.SYSTEM;

    @Builder.Default
    @Column(name = "push_notifications", nullable = false)
    private boolean pushNotifications = true;

    @Builder.Default
    @Column(name = "email_notifications", nullable = false)
    private boolean emailNotifications = true;

    @Builder.Default
    @Column(name = "budget_alerts", nullable = false)
    private boolean budgetAlerts = true;

    @Builder.Default
    @Column(name = "weekly_summary", nullable = false)
    private boolean weeklySummary = true;

    @Builder.Default
    @Column(name = "ai_suggestions", nullable = false)
    private boolean aiSuggestions = true;

    @Builder.Default
    @Column(name = "first_day_of_week", nullable = false)
    private int firstDayOfWeek = 0;

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getCurrency() {
        return currency;
    }

    public void setCurrency(String currency) {
        this.currency = currency;
    }

    public String getLocale() {
        return locale;
    }

    public void setLocale(String locale) {
        this.locale = locale;
    }

    public String getTimeZone() {
        return timeZone;
    }

    public void setTimeZone(String timeZone) {
        this.timeZone = timeZone;
    }

    public SystemThemes getTheme() {
        return theme;
    }

    public void setTheme(SystemThemes theme) {
        this.theme = theme;
    }

    public boolean isPushNotifications() {
        return pushNotifications;
    }

    public void setPushNotifications(boolean pushNotifications) {
        this.pushNotifications = pushNotifications;
    }

    public boolean isEmailNotifications() {
        return emailNotifications;
    }

    public void setEmailNotifications(boolean emailNotifications) {
        this.emailNotifications = emailNotifications;
    }

    public boolean isBudgetAlerts() {
        return budgetAlerts;
    }

    public void setBudgetAlerts(boolean budgetAlerts) {
        this.budgetAlerts = budgetAlerts;
    }

    public boolean isWeeklySummary() {
        return weeklySummary;
    }

    public void setWeeklySummary(boolean weeklySummary) {
        this.weeklySummary = weeklySummary;
    }

    public boolean isAiSuggestions() {
        return aiSuggestions;
    }

    public void setAiSuggestions(boolean aiSuggestions) {
        this.aiSuggestions = aiSuggestions;
    }

    public int getFirstDayOfWeek() {
        return firstDayOfWeek;
    }

    public void setFirstDayOfWeek(int firstDayOfWeek) {
        this.firstDayOfWeek = firstDayOfWeek;
    }

    public UserPreferences() {
        this.currency = "BRL";
        this.locale = "pt-BR";
        this.timeZone = "America/Sao_Paulo";
        this.theme = SystemThemes.SYSTEM;
        this.pushNotifications = true;
        this.emailNotifications = true;
        this.budgetAlerts = true;
        this.weeklySummary = true;
        this.aiSuggestions = true;
        this.firstDayOfWeek = 0;
    }

    public UserPreferences(UUID id, User user, String currency, String locale, String timeZone, SystemThemes theme,
            boolean pushNotifications, boolean emailNotifications, boolean budgetAlerts, boolean weeklySummary,
            boolean aiSuggestions, int firstDayOfWeek) {
        this.id = id;
        this.user = user;
        this.currency = currency;
        this.locale = locale;
        this.timeZone = timeZone;
        this.theme = theme;
        this.pushNotifications = pushNotifications;
        this.emailNotifications = emailNotifications;
        this.budgetAlerts = budgetAlerts;
        this.weeklySummary = weeklySummary;
        this.aiSuggestions = aiSuggestions;
        this.firstDayOfWeek = firstDayOfWeek;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((user == null) ? 0 : user.hashCode());
        result = prime * result + ((currency == null) ? 0 : currency.hashCode());
        result = prime * result + ((locale == null) ? 0 : locale.hashCode());
        result = prime * result + ((timeZone == null) ? 0 : timeZone.hashCode());
        result = prime * result + ((theme == null) ? 0 : theme.hashCode());
        result = prime * result + (pushNotifications ? 1231 : 1237);
        result = prime * result + (emailNotifications ? 1231 : 1237);
        result = prime * result + (budgetAlerts ? 1231 : 1237);
        result = prime * result + (weeklySummary ? 1231 : 1237);
        result = prime * result + (aiSuggestions ? 1231 : 1237);
        result = prime * result + firstDayOfWeek;
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        UserPreferences other = (UserPreferences) obj;
        if (id == null) {
            if (other.id != null)
                return false;
        } else if (!id.equals(other.id))
            return false;
        if (user == null) {
            if (other.user != null)
                return false;
        } else if (!user.equals(other.user))
            return false;
        if (currency == null) {
            if (other.currency != null)
                return false;
        } else if (!currency.equals(other.currency))
            return false;
        if (locale == null) {
            if (other.locale != null)
                return false;
        } else if (!locale.equals(other.locale))
            return false;
        if (timeZone == null) {
            if (other.timeZone != null)
                return false;
        } else if (!timeZone.equals(other.timeZone))
            return false;
        if (theme != other.theme)
            return false;
        if (pushNotifications != other.pushNotifications)
            return false;
        if (emailNotifications != other.emailNotifications)
            return false;
        if (budgetAlerts != other.budgetAlerts)
            return false;
        if (weeklySummary != other.weeklySummary)
            return false;
        if (aiSuggestions != other.aiSuggestions)
            return false;
        if (firstDayOfWeek != other.firstDayOfWeek)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "UserPreferences [id=" + id + ", user=" + user + ", currency=" + currency + ", locale=" + locale
                + ", timeZone=" + timeZone + ", theme=" + theme + ", pushNotifications=" + pushNotifications
                + ", emailNotifications=" + emailNotifications + ", budgetAlerts=" + budgetAlerts + ", weeklySummary="
                + weeklySummary + ", aiSuggestions=" + aiSuggestions + ", firstDayOfWeek=" + firstDayOfWeek + "]";
    }

}
