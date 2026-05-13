package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.RiskTolerance;

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
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;

@Entity
@Table(name = "risk_profiles", indexes = {
        @Index(name = "idx_risk_profiles_user_id", columnList = "user_id"),
        @Index(name = "idx_risk_profiles_risk_tolerance", columnList = "risk_tolerance")
})
public class RiskProfile extends AbstractAuditingEntity<UUID> {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id")
    private UUID id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", unique = true)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "risk_tolerance", length = 20, nullable = false)
    private RiskTolerance riskTolerance;

    @Column(name = "investment_horizon_years", nullable = false)
    private Integer investmentHorizonYears;

    @Column(name = "monthly_income", precision = 15, scale = 2)
    private BigDecimal monthlyIncome;

    @Column(name = "monthly_expenses", precision = 15, scale = 2)
    private BigDecimal monthlyExpenses;

    @Column(name = "emergency_fund", precision = 15, scale = 2)
    private BigDecimal emergencyFund;

    @Column(name = "total_investments", precision = 15, scale = 2)
    private BigDecimal totalInvestments;

    @Column(name = "questionnaire_answers", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String questionnaireAnswers;

    @Column(name = "calculated_score", nullable = false, precision = 5, scale = 2)
    private BigDecimal calculatedScore;

    @Column(name = "last_assessment_at", nullable = false)
    private Instant lastAssessmentAt = Instant.now();

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    public RiskProfile() {
    }

    public RiskProfile(UUID id, User user, RiskTolerance riskTolerance, Integer investmentHorizonYears,
            BigDecimal monthlyIncome, BigDecimal monthlyExpenses, BigDecimal emergencyFund,
            BigDecimal totalInvestments, String questionnaireAnswers, BigDecimal calculatedScore,
            Instant lastAssessmentAt) {
        this.id = id;
        this.user = user;
        this.riskTolerance = riskTolerance;
        this.investmentHorizonYears = investmentHorizonYears;
        this.monthlyIncome = monthlyIncome;
        this.monthlyExpenses = monthlyExpenses;
        this.emergencyFund = emergencyFund;
        this.totalInvestments = totalInvestments;
        this.questionnaireAnswers = questionnaireAnswers;
        this.calculatedScore = calculatedScore;
        this.lastAssessmentAt = lastAssessmentAt;
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

    public RiskTolerance getRiskTolerance() {
        return riskTolerance;
    }

    public void setRiskTolerance(RiskTolerance riskTolerance) {
        this.riskTolerance = riskTolerance;
    }

    public Integer getInvestmentHorizonYears() {
        return investmentHorizonYears;
    }

    public void setInvestmentHorizonYears(Integer investmentHorizonYears) {
        this.investmentHorizonYears = investmentHorizonYears;
    }

    public BigDecimal getMonthlyIncome() {
        return monthlyIncome;
    }

    public void setMonthlyIncome(BigDecimal monthlyIncome) {
        this.monthlyIncome = monthlyIncome;
    }

    public BigDecimal getMonthlyExpenses() {
        return monthlyExpenses;
    }

    public void setMonthlyExpenses(BigDecimal monthlyExpenses) {
        this.monthlyExpenses = monthlyExpenses;
    }

    public BigDecimal getEmergencyFund() {
        return emergencyFund;
    }

    public void setEmergencyFund(BigDecimal emergencyFund) {
        this.emergencyFund = emergencyFund;
    }

    public BigDecimal getTotalInvestments() {
        return totalInvestments;
    }

    public void setTotalInvestments(BigDecimal totalInvestments) {
        this.totalInvestments = totalInvestments;
    }

    public String getQuestionnaireAnswers() {
        return questionnaireAnswers;
    }

    public void setQuestionnaireAnswers(String questionnaireAnswers) {
        this.questionnaireAnswers = questionnaireAnswers;
    }

    public BigDecimal getCalculatedScore() {
        return calculatedScore;
    }

    public void setCalculatedScore(BigDecimal calculatedScore) {
        this.calculatedScore = calculatedScore;
    }

    public Instant getLastAssessmentAt() {
        return lastAssessmentAt;
    }

    public void setLastAssessmentAt(Instant lastAssessmentAt) {
        this.lastAssessmentAt = lastAssessmentAt;
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
