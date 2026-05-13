package com.fyna.Fyna.core.shared.domain;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.InvestmentRecommendationType;

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
@Table(name = "investment_recommendations", indexes = {
        @Index(name = "idx_investment_recommendations_user_id", columnList = "user_id"),
        @Index(name = "idx_investment_recommendations_risk_profile", columnList = "risk_profile_id"),
        @Index(name = "idx_investment_recommendations_type", columnList = "recommendation_type"),
        @Index(name = "idx_investment_recommendations_was_viewed", columnList = "was_viewed"),
        @Index(name = "idx_investment_recommendations_generated_at", columnList = "generated_at")
})
public class InvestmentRecommendation implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "risk_profile_id")
    private RiskProfile riskProfile;

    @Enumerated(EnumType.STRING)
    @Column(name = "recommendation_type", length = 30, nullable = false)
    private InvestmentRecommendationType recommendationType;

    @Column(name = "title", length = 200, nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "TEXT", nullable = false)
    private String description;

    @Column(name = "allocation_suggestion", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String allocationSuggestion;

    @Column(name = "potential_return", precision = 5, scale = 2)
    private BigDecimal potentialReturn;

    @Column(name = "risk_level", precision = 5, scale = 2)
    private BigDecimal riskLevel;

    @Column(name = "was_viewed", nullable = false)
    private Boolean wasViewed = false;

    @Column(name = "was_followed")
    private Boolean wasFollowed;

    @Column(name = "model_version", length = 50, nullable = false)
    private String modelVersion;

    @Column(name = "generated_at", nullable = false)
    private Instant generatedAt = Instant.now();

    @Column(name = "viewed_at")
    private Instant viewedAt;

    public InvestmentRecommendation() {
    }

    public InvestmentRecommendation(UUID id, User user, RiskProfile riskProfile,
            InvestmentRecommendationType recommendationType, String title, String description,
            String allocationSuggestion, BigDecimal potentialReturn, BigDecimal riskLevel,
            Boolean wasViewed, Boolean wasFollowed, String modelVersion, Instant generatedAt,
            Instant viewedAt) {
        this.id = id;
        this.user = user;
        this.riskProfile = riskProfile;
        this.recommendationType = recommendationType;
        this.title = title;
        this.description = description;
        this.allocationSuggestion = allocationSuggestion;
        this.potentialReturn = potentialReturn;
        this.riskLevel = riskLevel;
        this.wasViewed = wasViewed;
        this.wasFollowed = wasFollowed;
        this.modelVersion = modelVersion;
        this.generatedAt = generatedAt;
        this.viewedAt = viewedAt;
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

    public RiskProfile getRiskProfile() {
        return riskProfile;
    }

    public void setRiskProfile(RiskProfile riskProfile) {
        this.riskProfile = riskProfile;
    }

    public InvestmentRecommendationType getRecommendationType() {
        return recommendationType;
    }

    public void setRecommendationType(InvestmentRecommendationType recommendationType) {
        this.recommendationType = recommendationType;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getAllocationSuggestion() {
        return allocationSuggestion;
    }

    public void setAllocationSuggestion(String allocationSuggestion) {
        this.allocationSuggestion = allocationSuggestion;
    }

    public BigDecimal getPotentialReturn() {
        return potentialReturn;
    }

    public void setPotentialReturn(BigDecimal potentialReturn) {
        this.potentialReturn = potentialReturn;
    }

    public BigDecimal getRiskLevel() {
        return riskLevel;
    }

    public void setRiskLevel(BigDecimal riskLevel) {
        this.riskLevel = riskLevel;
    }

    public Boolean getWasViewed() {
        return wasViewed;
    }

    public void setWasViewed(Boolean wasViewed) {
        this.wasViewed = wasViewed;
    }

    public Boolean getWasFollowed() {
        return wasFollowed;
    }

    public void setWasFollowed(Boolean wasFollowed) {
        this.wasFollowed = wasFollowed;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }

    public void setGeneratedAt(Instant generatedAt) {
        this.generatedAt = generatedAt;
    }

    public Instant getViewedAt() {
        return viewedAt;
    }

    public void setViewedAt(Instant viewedAt) {
        this.viewedAt = viewedAt;
    }
}
