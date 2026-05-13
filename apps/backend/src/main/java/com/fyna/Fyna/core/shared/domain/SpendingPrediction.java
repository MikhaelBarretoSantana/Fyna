package com.fyna.Fyna.core.shared.domain;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "spending_predictions", indexes = {
        @Index(name = "idx_spending_predictions_user_id", columnList = "user_id"),
        @Index(name = "idx_spending_predictions_category_id", columnList = "category_id"),
        @Index(name = "idx_spending_predictions_date", columnList = "prediction_date"),
        @Index(name = "idx_spending_predictions_generated_at", columnList = "generated_at"),
        @Index(name = "idx_spending_predictions_user_category_date", columnList = "user_id,category_id,prediction_date")
})
public class SpendingPrediction implements Serializable {

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

    @Column(name = "prediction_date", nullable = false)
    private LocalDate predictionDate;

    @Column(name = "predicted_amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal predictedAmount;

    @Column(name = "actual_amount", precision = 15, scale = 2)
    private BigDecimal actualAmount;

    @Column(name = "confidence_lower", nullable = false, precision = 15, scale = 2)
    private BigDecimal confidenceLower;

    @Column(name = "confidence_upper", nullable = false, precision = 15, scale = 2)
    private BigDecimal confidenceUpper;

    @Column(name = "model_version", length = 50, nullable = false)
    private String modelVersion;

    @Column(name = "model_parameters", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String modelParameters;

    @Column(name = "generated_at", nullable = false)
    private Instant generatedAt = Instant.now();

    public SpendingPrediction() {
    }

    public SpendingPrediction(UUID id, User user, Categories category, LocalDate predictionDate,
            BigDecimal predictedAmount, BigDecimal actualAmount, BigDecimal confidenceLower,
            BigDecimal confidenceUpper, String modelVersion, String modelParameters) {
        this.id = id;
        this.user = user;
        this.category = category;
        this.predictionDate = predictionDate;
        this.predictedAmount = predictedAmount;
        this.actualAmount = actualAmount;
        this.confidenceLower = confidenceLower;
        this.confidenceUpper = confidenceUpper;
        this.modelVersion = modelVersion;
        this.modelParameters = modelParameters;
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

    public Categories getCategory() {
        return category;
    }

    public void setCategory(Categories category) {
        this.category = category;
    }

    public LocalDate getPredictionDate() {
        return predictionDate;
    }

    public void setPredictionDate(LocalDate predictionDate) {
        this.predictionDate = predictionDate;
    }

    public BigDecimal getPredictedAmount() {
        return predictedAmount;
    }

    public void setPredictedAmount(BigDecimal predictedAmount) {
        this.predictedAmount = predictedAmount;
    }

    public BigDecimal getActualAmount() {
        return actualAmount;
    }

    public void setActualAmount(BigDecimal actualAmount) {
        this.actualAmount = actualAmount;
    }

    public BigDecimal getConfidenceLower() {
        return confidenceLower;
    }

    public void setConfidenceLower(BigDecimal confidenceLower) {
        this.confidenceLower = confidenceLower;
    }

    public BigDecimal getConfidenceUpper() {
        return confidenceUpper;
    }

    public void setConfidenceUpper(BigDecimal confidenceUpper) {
        this.confidenceUpper = confidenceUpper;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public String getModelParameters() {
        return modelParameters;
    }

    public void setModelParameters(String modelParameters) {
        this.modelParameters = modelParameters;
    }

    public Instant getGeneratedAt() {
        return generatedAt;
    }

    public void setGeneratedAt(Instant generatedAt) {
        this.generatedAt = generatedAt;
    }
}
