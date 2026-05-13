package com.fyna.Fyna.core.features.risk.domain.service;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.BadRequestException;
import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.risk.data.repository.RiskProfileRepository;
import com.fyna.Fyna.core.features.risk.presentation.dto.CreateRiskProfileRequest;
import com.fyna.Fyna.core.features.risk.presentation.dto.RiskProfileResponse;
import com.fyna.Fyna.core.features.risk.presentation.dto.UpdateRiskProfileRequest;
import com.fyna.Fyna.core.shared.domain.RiskProfile;
import com.fyna.Fyna.core.shared.domain.User;

@Service
public class RiskProfileService {

    private final RiskProfileRepository riskProfileRepository;
    private final UserRepository userRepository;

    public RiskProfileService(RiskProfileRepository riskProfileRepository, UserRepository userRepository) {
        this.riskProfileRepository = riskProfileRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public RiskProfileResponse getRiskProfile(UUID userId) {
        RiskProfile profile = riskProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("RiskProfile", "userId", userId));
        return RiskProfileResponse.from(profile);
    }

    @Transactional
    public RiskProfileResponse createRiskProfile(UUID userId, CreateRiskProfileRequest request) {
        if (riskProfileRepository.existsByUserId(userId)) {
            throw new BadRequestException("Perfil de risco já existe para este usuário. Use PUT para atualizar.");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        RiskProfile profile = new RiskProfile();
        profile.setUser(user);
        profile.setRiskTolerance(request.riskTolerance());
        profile.setInvestmentHorizonYears(request.investmentHorizonYears());
        profile.setMonthlyIncome(request.monthlyIncome());
        profile.setMonthlyExpenses(request.monthlyExpenses());
        profile.setEmergencyFund(request.emergencyFund());
        profile.setTotalInvestments(request.totalInvestments());
        profile.setQuestionnaireAnswers(request.questionnaireAnswers());
        profile.setCalculatedScore(calculateRiskScore(request));
        profile.setLastAssessmentAt(Instant.now());

        profile = riskProfileRepository.save(profile);
        return RiskProfileResponse.from(profile);
    }

    @Transactional
    public RiskProfileResponse updateRiskProfile(UUID userId, UpdateRiskProfileRequest request) {
        RiskProfile profile = riskProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("RiskProfile", "userId", userId));

        if (request.riskTolerance() != null) profile.setRiskTolerance(request.riskTolerance());
        if (request.investmentHorizonYears() != null) profile.setInvestmentHorizonYears(request.investmentHorizonYears());
        if (request.monthlyIncome() != null) profile.setMonthlyIncome(request.monthlyIncome());
        if (request.monthlyExpenses() != null) profile.setMonthlyExpenses(request.monthlyExpenses());
        if (request.emergencyFund() != null) profile.setEmergencyFund(request.emergencyFund());
        if (request.totalInvestments() != null) profile.setTotalInvestments(request.totalInvestments());
        if (request.questionnaireAnswers() != null) profile.setQuestionnaireAnswers(request.questionnaireAnswers());

        profile.setCalculatedScore(recalculateScore(profile));
        profile.setLastAssessmentAt(Instant.now());

        profile = riskProfileRepository.save(profile);
        return RiskProfileResponse.from(profile);
    }

    @Transactional
    public void deleteRiskProfile(UUID userId) {
        RiskProfile profile = riskProfileRepository.findByUserId(userId)
                .orElseThrow(() -> new ResourceNotFoundException("RiskProfile", "userId", userId));
        riskProfileRepository.delete(profile);
    }

    /**
     * Calcula o score de risco baseado nas respostas do questionário.
     * Implementação simplificada — o cálculo real será feito pelo serviço de IA.
     */
    private BigDecimal calculateRiskScore(CreateRiskProfileRequest request) {
        int score = switch (request.riskTolerance()) {
            case CONSERVATIVE -> 20;
            case MODERATELY_CONSERVATIVE -> 35;
            case MODERATE -> 50;
            case MODERATELY_AGGRESSIVE -> 70;
            case AGGRESSIVE -> 85;
        };

        if (request.investmentHorizonYears() > 10) score += 10;
        else if (request.investmentHorizonYears() > 5) score += 5;

        return BigDecimal.valueOf(Math.min(score, 100));
    }

    private BigDecimal recalculateScore(RiskProfile profile) {
        int score = switch (profile.getRiskTolerance()) {
            case CONSERVATIVE -> 20;
            case MODERATELY_CONSERVATIVE -> 35;
            case MODERATE -> 50;
            case MODERATELY_AGGRESSIVE -> 70;
            case AGGRESSIVE -> 85;
        };

        if (profile.getInvestmentHorizonYears() > 10) score += 10;
        else if (profile.getInvestmentHorizonYears() > 5) score += 5;

        return BigDecimal.valueOf(Math.min(score, 100));
    }
}
