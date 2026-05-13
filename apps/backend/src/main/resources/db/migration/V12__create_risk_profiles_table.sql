-- ============================================
-- FYNA - Finance AI Application
-- Migration V12: Create Risk Profiles Table
-- ============================================

CREATE TABLE risk_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    risk_tolerance VARCHAR(20) NOT NULL,
    investment_horizon_years INTEGER NOT NULL,
    monthly_income DECIMAL(15, 2),
    monthly_expenses DECIMAL(15, 2),
    emergency_fund DECIMAL(15, 2),
    total_investments DECIMAL(15, 2),
    questionnaire_answers JSONB,
    calculated_score DECIMAL(5, 2) NOT NULL,
    last_assessment_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_risk_profiles_user_id UNIQUE (user_id),
    CONSTRAINT fk_risk_profiles_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_risk_profiles_risk_tolerance CHECK (risk_tolerance IN (
        'CONSERVATIVE', 'MODERATELY_CONSERVATIVE', 'MODERATE', 
        'MODERATELY_AGGRESSIVE', 'AGGRESSIVE'
    )),
    CONSTRAINT chk_risk_profiles_horizon CHECK (investment_horizon_years > 0),
    CONSTRAINT chk_risk_profiles_score CHECK (calculated_score BETWEEN 0 AND 100)
);

-- Index
CREATE INDEX idx_risk_profiles_user_id ON risk_profiles (user_id);
CREATE INDEX idx_risk_profiles_risk_tolerance ON risk_profiles (risk_tolerance);

-- Comments
COMMENT ON TABLE risk_profiles IS 'Stores user investment risk profile assessment';
COMMENT ON COLUMN risk_profiles.risk_tolerance IS 'Risk tolerance level based on assessment';
COMMENT ON COLUMN risk_profiles.questionnaire_answers IS 'JSON with all risk assessment questionnaire responses';
COMMENT ON COLUMN risk_profiles.calculated_score IS 'Numerical risk score from 0 (conservative) to 100 (aggressive)';
