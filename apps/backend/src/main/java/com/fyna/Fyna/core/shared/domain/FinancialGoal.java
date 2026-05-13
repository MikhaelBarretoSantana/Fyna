package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.FinancialGoalPriority;
import com.fyna.Fyna.core.shared.enums.FinancialGoalStatus;

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
@Table(name = "financial_goals", indexes = {
        @Index(name = "idx_financial_goals_user_id", columnList = "user_id"),
        @Index(name = "idx_financial_goals_status", columnList = "status"),
        @Index(name = "idx_financial_goals_priority", columnList = "priority"),
        @Index(name = "idx_financial_goals_target_date", columnList = "target_date"),
        @Index(name = "idx_financial_goals_user_status", columnList = "user_id,status")
})
public class FinancialGoal extends AbstractAuditingEntity<UUID> {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "icon", length = 50)
    private String icon;

    @Column(name = "color", length = 7)
    private String color;

    @Column(name = "target_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal targetAmount;

    @Column(name = "current_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal currentAmount = BigDecimal.ZERO;

    @Column(name = "target_date")
    private LocalDate targetDate;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", length = 20, nullable = false)
    private FinancialGoalStatus status = FinancialGoalStatus.IN_PROGRESS;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", length = 10, nullable = false)
    private FinancialGoalPriority priority = FinancialGoalPriority.MEDIUM;

    @Column(name = "completed_at")
    private Instant completedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public FinancialGoal() {
    }

    public FinancialGoal(UUID id, User user, String name, String description, String icon, String color,
            BigDecimal targetAmount, BigDecimal currentAmount, LocalDate targetDate,
            FinancialGoalStatus status, FinancialGoalPriority priority, Instant completedAt) {
        this.id = id;
        this.user = user;
        this.name = name;
        this.description = description;
        this.icon = icon;
        this.color = color;
        this.targetAmount = targetAmount;
        this.currentAmount = currentAmount;
        this.targetDate = targetDate;
        this.status = status;
        this.priority = priority;
        this.completedAt = completedAt;
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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public BigDecimal getTargetAmount() {
        return targetAmount;
    }

    public void setTargetAmount(BigDecimal targetAmount) {
        this.targetAmount = targetAmount;
    }

    public BigDecimal getCurrentAmount() {
        return currentAmount;
    }

    public void setCurrentAmount(BigDecimal currentAmount) {
        this.currentAmount = currentAmount;
    }

    public LocalDate getTargetDate() {
        return targetDate;
    }

    public void setTargetDate(LocalDate targetDate) {
        this.targetDate = targetDate;
    }

    public FinancialGoalStatus getStatus() {
        return status;
    }

    public void setStatus(FinancialGoalStatus status) {
        this.status = status;
    }

    public FinancialGoalPriority getPriority() {
        return priority;
    }

    public void setPriority(FinancialGoalPriority priority) {
        this.priority = priority;
    }

    public Instant getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(Instant completedAt) {
        this.completedAt = completedAt;
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
