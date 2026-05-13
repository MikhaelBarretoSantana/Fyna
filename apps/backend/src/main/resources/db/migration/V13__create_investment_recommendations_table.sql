-- ============================================
-- FYNA - Finance AI Application
-- Migration V13: Create Investment Recommendations Table
-- ============================================

CREATE TABLE investment_recommendations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    risk_profile_id UUID,
    recommendation_type VARCHAR(30) NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    allocation_suggestion JSONB,
    potential_return DECIMAL(5, 2),
    risk_level DECIMAL(5, 2),
    was_viewed BOOLEAN NOT NULL DEFAULT FALSE,
    was_followed BOOLEAN,
    model_version VARCHAR(50) NOT NULL,
    generated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    viewed_at TIMESTAMP WITH TIME ZONE,
    
    CONSTRAINT fk_investment_recommendations_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_investment_recommendations_risk_profile FOREIGN KEY (risk_profile_id) 
        REFERENCES risk_profiles(id) ON DELETE SET NULL,
    CONSTRAINT chk_investment_recommendations_type CHECK (recommendation_type IN (
        'ASSET_ALLOCATION', 'REBALANCING', 'NEW_INVESTMENT', 
        'RISK_ADJUSTMENT', 'TAX_OPTIMIZATION', 'DIVERSIFICATION'
    )),
    CONSTRAINT chk_investment_recommendations_return CHECK (potential_return BETWEEN -100 AND 1000),
    CONSTRAINT chk_investment_recommendations_risk CHECK (risk_level BETWEEN 0 AND 100)
);

-- Indexes
CREATE INDEX idx_investment_recommendations_user_id ON investment_recommendations (user_id);
CREATE INDEX idx_investment_recommendations_risk_profile ON investment_recommendations (risk_profile_id);
CREATE INDEX idx_investment_recommendations_type ON investment_recommendations (recommendation_type);
CREATE INDEX idx_investment_recommendations_was_viewed ON investment_recommendations (was_viewed);
CREATE INDEX idx_investment_recommendations_generated_at ON investment_recommendations (generated_at);

-- Comments
COMMENT ON TABLE investment_recommendations IS 'Stores AI-generated investment recommendations';
COMMENT ON COLUMN investment_recommendations.recommendation_type IS 'Type of recommendation: ASSET_ALLOCATION, REBALANCING, etc.';
COMMENT ON COLUMN investment_recommendations.allocation_suggestion IS 'JSON with suggested portfolio allocation';
COMMENT ON COLUMN investment_recommendations.potential_return IS 'Expected annual return percentage';
COMMENT ON COLUMN investment_recommendations.risk_level IS 'Risk level score from 0 to 100';
