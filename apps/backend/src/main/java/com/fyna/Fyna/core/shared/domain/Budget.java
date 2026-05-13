package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.BudgetPeriodType;

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
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "budgets", indexes = {
        @Index(name = "idx_budgets_user_id", columnList = "user_id"),
        @Index(name = "idx_budgets_category_id", columnList = "category_id"),
        @Index(name = "idx_budgets_period_type", columnList = "period_type"),
        @Index(name = "idx_budgets_is_active", columnList = "is_active"),
        @Index(name = "idx_budgets_dates", columnList = "start_date,end_date"),
        @Index(name = "idx_budgets_user_active_dates", columnList = "user_id,is_active,start_date,end_date")
})
public class Budget extends AbstractAuditingEntity<UUID> {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Categories category;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Column(name = "amount_limit", nullable = false, precision = 15, scale = 2)
    private BigDecimal amountLimit;

    @Column(name = "amount_spent", nullable = false, precision = 15, scale = 2)
    private BigDecimal amountSpent = BigDecimal.ZERO;

    @Enumerated(EnumType.STRING)
    @Column(name = "period_type", length = 20, nullable = false)
    private BudgetPeriodType periodType;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "alert_threshold", nullable = false, precision = 5, scale = 2)
    private BigDecimal alertThreshold = new BigDecimal("80.00");

    @Column(name = "alert_enabled", nullable = false)
    private Boolean alertEnabled = true;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public Budget() {
    }

    public Budget(UUID id, User user, Categories category, String name, BigDecimal amountLimit,
            BigDecimal amountSpent, BudgetPeriodType periodType, LocalDate startDate, LocalDate endDate,
            BigDecimal alertThreshold, Boolean alertEnabled, Boolean isActive) {
        this.id = id;
        this.user = user;
        this.category = category;
        this.name = name;
        this.amountLimit = amountLimit;
        this.amountSpent = amountSpent;
        this.periodType = periodType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.alertThreshold = alertThreshold;
        this.alertEnabled = alertEnabled;
        this.isActive = isActive;
    }

    @Override
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

    public Categories getCategory() {
        return category;
    }

    public void setCategory(Categories category) {
        this.category = category;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BigDecimal getAmountLimit() {
        return amountLimit;
    }

    public void setAmountLimit(BigDecimal amountLimit) {
        this.amountLimit = amountLimit;
    }

    public BigDecimal getAmountSpent() {
        return amountSpent;
    }

    public void setAmountSpent(BigDecimal amountSpent) {
        this.amountSpent = amountSpent;
    }

    public BudgetPeriodType getPeriodType() {
        return periodType;
    }

    public void setPeriodType(BudgetPeriodType periodType) {
        this.periodType = periodType;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public BigDecimal getAlertThreshold() {
        return alertThreshold;
    }

    public void setAlertThreshold(BigDecimal alertThreshold) {
        this.alertThreshold = alertThreshold;
    }

    public Boolean getAlertEnabled() {
        return alertEnabled;
    }

    public void setAlertEnabled(Boolean alertEnabled) {
        this.alertEnabled = alertEnabled;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Instant createdAt) {
        this.createdAt = createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Instant updatedAt) {
        this.updatedAt = updatedAt;
    }
}
