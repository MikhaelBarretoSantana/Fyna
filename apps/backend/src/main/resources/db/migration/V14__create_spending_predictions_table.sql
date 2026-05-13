-- ============================================
-- FYNA - Finance AI Application
-- Migration V14: Create Spending Predictions Table
-- ============================================

CREATE TABLE spending_predictions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    category_id UUID,
    prediction_date DATE NOT NULL,
    predicted_amount DECIMAL(15, 2) NOT NULL,
    actual_amount DECIMAL(15, 2),
    confidence_lower DECIMAL(15, 2) NOT NULL,
    confidence_upper DECIMAL(15, 2) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    model_parameters JSONB,
    generated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_spending_predictions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_spending_predictions_category FOREIGN KEY (category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT chk_spending_predictions_amounts CHECK (
        predicted_amount >= 0 AND 
        confidence_lower >= 0 AND 
        confidence_upper >= confidence_lower
    )
);

-- Indexes
CREATE INDEX idx_spending_predictions_user_id ON spending_predictions (user_id);
CREATE INDEX idx_spending_predictions_category_id ON spending_predictions (category_id);
CREATE INDEX idx_spending_predictions_date ON spending_predictions (prediction_date);
CREATE INDEX idx_spending_predictions_generated_at ON spending_predictions (generated_at);

-- Composite index for prediction lookup
CREATE INDEX idx_spending_predictions_user_category_date ON spending_predictions (user_id, category_id, prediction_date);

-- Comments
COMMENT ON TABLE spending_predictions IS 'Stores AI-generated spending predictions';
COMMENT ON COLUMN spending_predictions.category_id IS 'NULL for total spending, category_id for category-specific prediction';
COMMENT ON COLUMN spending_predictions.prediction_date IS 'Date or month for which spending is predicted';
COMMENT ON COLUMN spending_predictions.confidence_lower IS 'Lower bound of confidence interval';
COMMENT ON COLUMN spending_predictions.confidence_upper IS 'Upper bound of confidence interval';
