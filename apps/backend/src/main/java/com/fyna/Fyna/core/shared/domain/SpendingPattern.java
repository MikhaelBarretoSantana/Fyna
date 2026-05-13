package com.fyna.Fyna.core.shared.domain;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.SpendingPatternType;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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
@Table(name = "spending_patterns", indexes = {
        @Index(name = "idx_spending_patterns_user_id", columnList = "user_id"),
        @Index(name = "idx_spending_patterns_type", columnList = "pattern_type"),
        @Index(name = "idx_spending_patterns_is_active", columnList = "is_active"),
        @Index(name = "idx_spending_patterns_significance", columnList = "significance_score"),
        @Index(name = "idx_spending_patterns_detected_at", columnList = "detected_at")
})
public class SpendingPattern implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "pattern_type", length = 30, nullable = false)
    private SpendingPatternType patternType;

    @Column(name = "description", columnDefinition = "TEXT", nullable = false)
    private String description;

    @Column(name = "pattern_data", columnDefinition = "jsonb", nullable = false)
    @JdbcTypeCode(SqlTypes.JSON)
    private String patternData;

    @Column(name = "significance_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal significanceScore;

    @Column(name = "detected_from", nullable = false)
    private LocalDate detectedFrom;

    @Column(name = "detected_to", nullable = false)
    private LocalDate detectedTo;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "model_version", length = 50, nullable = false)
    private String modelVersion;

    @Column(name = "detected_at", nullable = false)
    private Instant detectedAt = Instant.now();

    public SpendingPattern() {
    }

    public SpendingPattern(UUID id, User user, SpendingPatternType patternType, String description,
            String patternData, BigDecimal significanceScore, LocalDate detectedFrom, LocalDate detectedTo,
            Boolean isActive, String modelVersion) {
        this.id = id;
        this.user = user;
        this.patternType = patternType;
        this.description = description;
        this.patternData = patternData;
        this.significanceScore = significanceScore;
        this.detectedFrom = detectedFrom;
        this.detectedTo = detectedTo;
        this.isActive = isActive;
        this.modelVersion = modelVersion;
    }

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

    public SpendingPatternType getPatternType() {
        return patternType;
    }

    public void setPatternType(SpendingPatternType patternType) {
        this.patternType = patternType;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getPatternData() {
        return patternData;
    }

    public void setPatternData(String patternData) {
        this.patternData = patternData;
    }

    public BigDecimal getSignificanceScore() {
        return significanceScore;
    }

    public void setSignificanceScore(BigDecimal significanceScore) {
        this.significanceScore = significanceScore;
    }

    public LocalDate getDetectedFrom() {
        return detectedFrom;
    }

    public void setDetectedFrom(LocalDate detectedFrom) {
        this.detectedFrom = detectedFrom;
    }

    public LocalDate getDetectedTo() {
        return detectedTo;
    }

    public void setDetectedTo(LocalDate detectedTo) {
        this.detectedTo = detectedTo;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public Instant getDetectedAt() {
        return detectedAt;
    }

    public void setDetectedAt(Instant detectedAt) {
        this.detectedAt = detectedAt;
    }
}
