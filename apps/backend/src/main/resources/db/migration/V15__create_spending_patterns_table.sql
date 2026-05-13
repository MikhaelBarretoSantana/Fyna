-- ============================================
-- FYNA - Finance AI Application
-- Migration V15: Create Spending Patterns Table
-- ============================================

CREATE TABLE spending_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    pattern_type VARCHAR(30) NOT NULL,
    description TEXT NOT NULL,
    pattern_data JSONB NOT NULL,
    significance_score DECIMAL(5, 4) NOT NULL,
    detected_from DATE NOT NULL,
    detected_to DATE NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    model_version VARCHAR(50) NOT NULL,
    detected_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_spending_patterns_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_spending_patterns_type CHECK (pattern_type IN (
        'SEASONAL', 'TREND', 'ANOMALY', 'RECURRING', 
        'CATEGORY_SHIFT', 'INCOME_CHANGE', 'LIFESTYLE_CHANGE'
    )),
    CONSTRAINT chk_spending_patterns_significance CHECK (significance_score BETWEEN 0 AND 1),
    CONSTRAINT chk_spending_patterns_dates CHECK (detected_to >= detected_from)
);

-- Indexes
CREATE INDEX idx_spending_patterns_user_id ON spending_patterns (user_id);
CREATE INDEX idx_spending_patterns_type ON spending_patterns (pattern_type);
CREATE INDEX idx_spending_patterns_is_active ON spending_patterns (is_active);
CREATE INDEX idx_spending_patterns_significance ON spending_patterns (significance_score);
CREATE INDEX idx_spending_patterns_detected_at ON spending_patterns (detected_at);

-- Comments
COMMENT ON TABLE spending_patterns IS 'Stores AI-detected spending patterns and anomalies';
COMMENT ON COLUMN spending_patterns.pattern_type IS 'Type of pattern: SEASONAL, TREND, ANOMALY, etc.';
COMMENT ON COLUMN spending_patterns.pattern_data IS 'JSON with detailed pattern information';
COMMENT ON COLUMN spending_patterns.significance_score IS 'Statistical significance score between 0 and 1';
