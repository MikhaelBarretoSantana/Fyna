package com.fyna.Fyna.core.shared.domain;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.Instant;
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
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

@Entity
@Table(name = "ai_classifications", indexes = {
        @Index(name = "idx_ai_classifications_transaction_id", columnList = "transaction_id"),
        @Index(name = "idx_ai_classifications_suggested_category", columnList = "suggested_category_id"),
        @Index(name = "idx_ai_classifications_confirmed_category", columnList = "confirmed_category_id"),
        @Index(name = "idx_ai_classifications_confidence", columnList = "confidence_score"),
        @Index(name = "idx_ai_classifications_model_version", columnList = "model_version"),
        @Index(name = "idx_ai_classifications_was_corrected", columnList = "was_corrected")
})
public class AIClassifications implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "transaction_id")
    private Transactions transactions;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "suggested_category_id")
    private Categories suggestedCategory;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "confirmed_category_id")
    private Categories confirmedCategory;

    @Column(name = "confidence_score", nullable = false, precision = 5, scale = 4)
    private BigDecimal confidenceScore;

    @Column(name = "original_text", length = 500, nullable = false)
    private String originalText;

    @Column(name = "model_version", length = 50, nullable = false)
    private String modelVersion;

    @Column(name = "was_confirmed", nullable = false)
    private Boolean wasConfirmed = false;

    @Column(name = "was_corrected", nullable = false)
    private Boolean wasCorrected = false;

    @Column(name = "feature_vector", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String featureVector;

    @Column(name = "classified_at", nullable = false)
    private Instant classifiedAt = Instant.now();

    @Column(name = "confirmed_at")
    private Instant confirmedAt;

    public AIClassifications() {
    }

    public AIClassifications(UUID id, Transactions transactions, Categories suggestedCategory,
            Categories confirmedCategory, BigDecimal confidenceScore, String originalText, String modelVersion,
            Boolean wasConfirmed, Boolean wasCorrected, String featureVector, Instant classifiedAt,
            Instant confirmedAt) {
        this.id = id;
        this.transactions = transactions;
        this.suggestedCategory = suggestedCategory;
        this.confirmedCategory = confirmedCategory;
        this.confidenceScore = confidenceScore;
        this.originalText = originalText;
        this.modelVersion = modelVersion;
        this.wasConfirmed = wasConfirmed;
        this.wasCorrected = wasCorrected;
        this.featureVector = featureVector;
        this.classifiedAt = classifiedAt;
        this.confirmedAt = confirmedAt;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public Transactions getTransactions() {
        return transactions;
    }

    public void setTransactions(Transactions transactions) {
        this.transactions = transactions;
    }

    public Categories getSuggestedCategory() {
        return suggestedCategory;
    }

    public void setSuggestedCategory(Categories suggestedCategory) {
        this.suggestedCategory = suggestedCategory;
    }

    public Categories getConfirmedCategory() {
        return confirmedCategory;
    }

    public void setConfirmedCategory(Categories confirmedCategory) {
        this.confirmedCategory = confirmedCategory;
    }

    public BigDecimal getConfidenceScore() {
        return confidenceScore;
    }

    public void setConfidenceScore(BigDecimal confidenceScore) {
        this.confidenceScore = confidenceScore;
    }

    public String getOriginalText() {
        return originalText;
    }

    public void setOriginalText(String originalText) {
        this.originalText = originalText;
    }

    public String getModelVersion() {
        return modelVersion;
    }

    public void setModelVersion(String modelVersion) {
        this.modelVersion = modelVersion;
    }

    public Boolean getWasConfirmed() {
        return wasConfirmed;
    }

    public void setWasConfirmed(Boolean wasConfirmed) {
        this.wasConfirmed = wasConfirmed;
    }

    public Boolean getWasCorrected() {
        return wasCorrected;
    }

    public void setWasCorrected(Boolean wasCorrected) {
        this.wasCorrected = wasCorrected;
    }

    public String getFeatureVector() {
        return featureVector;
    }

    public void setFeatureVector(String featureVector) {
        this.featureVector = featureVector;
    }

    public Instant getClassifiedAt() {
        return classifiedAt;
    }

    public void setClassifiedAt(Instant classifiedAt) {
        this.classifiedAt = classifiedAt;
    }

    public Instant getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(Instant confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((transactions == null) ? 0 : transactions.hashCode());
        result = prime * result + ((suggestedCategory == null) ? 0 : suggestedCategory.hashCode());
        result = prime * result + ((confirmedCategory == null) ? 0 : confirmedCategory.hashCode());
        result = prime * result + ((confidenceScore == null) ? 0 : confidenceScore.hashCode());
        result = prime * result + ((originalText == null) ? 0 : originalText.hashCode());
        result = prime * result + ((modelVersion == null) ? 0 : modelVersion.hashCode());
        result = prime * result + ((wasConfirmed == null) ? 0 : wasConfirmed.hashCode());
        result = prime * result + ((wasCorrected == null) ? 0 : wasCorrected.hashCode());
        result = prime * result + ((featureVector == null) ? 0 : featureVector.hashCode());
        result = prime * result + ((classifiedAt == null) ? 0 : classifiedAt.hashCode());
        result = prime * result + ((confirmedAt == null) ? 0 : confirmedAt.hashCode());
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
        AIClassifications other = (AIClassifications) obj;
        if (id == null) {
            if (other.id != null)
                return false;
        } else if (!id.equals(other.id))
            return false;
        if (transactions == null) {
            if (other.transactions != null)
                return false;
        } else if (!transactions.equals(other.transactions))
            return false;
        if (suggestedCategory == null) {
            if (other.suggestedCategory != null)
                return false;
        } else if (!suggestedCategory.equals(other.suggestedCategory))
            return false;
        if (confirmedCategory == null) {
            if (other.confirmedCategory != null)
                return false;
        } else if (!confirmedCategory.equals(other.confirmedCategory))
            return false;
        if (confidenceScore == null) {
            if (other.confidenceScore != null)
                return false;
        } else if (!confidenceScore.equals(other.confidenceScore))
            return false;
        if (originalText == null) {
            if (other.originalText != null)
                return false;
        } else if (!originalText.equals(other.originalText))
            return false;
        if (modelVersion == null) {
            if (other.modelVersion != null)
                return false;
        } else if (!modelVersion.equals(other.modelVersion))
            return false;
        if (wasConfirmed == null) {
            if (other.wasConfirmed != null)
                return false;
        } else if (!wasConfirmed.equals(other.wasConfirmed))
            return false;
        if (wasCorrected == null) {
            if (other.wasCorrected != null)
                return false;
        } else if (!wasCorrected.equals(other.wasCorrected))
            return false;
        if (featureVector == null) {
            if (other.featureVector != null)
                return false;
        } else if (!featureVector.equals(other.featureVector))
            return false;
        if (classifiedAt == null) {
            if (other.classifiedAt != null)
                return false;
        } else if (!classifiedAt.equals(other.classifiedAt))
            return false;
        if (confirmedAt == null) {
            if (other.confirmedAt != null)
                return false;
        } else if (!confirmedAt.equals(other.confirmedAt))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "AIClassifications [id=" + id + ", transactions=" + transactions + ", suggestedCategory="
                + suggestedCategory + ", confirmedCategory=" + confirmedCategory + ", confidenceScore="
                + confidenceScore + ", originalText=" + originalText + ", modelVersion=" + modelVersion
                + ", wasConfirmed=" + wasConfirmed + ", wasCorrected=" + wasCorrected + ", featureVector="
                + featureVector + ", classifiedAt=" + classifiedAt + ", confirmedAt=" + confirmedAt + "]";
    }

}
