-- ============================================
-- FYNA - Finance AI Application
-- Migration V10: Create Budgets Table
-- ============================================

CREATE TABLE budgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    category_id UUID,
    name VARCHAR(100) NOT NULL,
    amount_limit DECIMAL(15, 2) NOT NULL,
    amount_spent DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    period_type VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    alert_threshold DECIMAL(5, 2) NOT NULL DEFAULT 80.00,
    alert_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_budgets_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_budgets_category FOREIGN KEY (category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT chk_budgets_period_type CHECK (period_type IN (
        'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'QUARTERLY', 'YEARLY', 'CUSTOM'
    )),
    CONSTRAINT chk_budgets_amount_limit CHECK (amount_limit > 0),
    CONSTRAINT chk_budgets_amount_spent CHECK (amount_spent >= 0),
    CONSTRAINT chk_budgets_alert_threshold CHECK (alert_threshold BETWEEN 0 AND 100),
    CONSTRAINT chk_budgets_dates CHECK (end_date >= start_date)
);

-- Indexes
CREATE INDEX idx_budgets_user_id ON budgets (user_id);
CREATE INDEX idx_budgets_category_id ON budgets (category_id);
CREATE INDEX idx_budgets_period_type ON budgets (period_type);
CREATE INDEX idx_budgets_is_active ON budgets (is_active);
CREATE INDEX idx_budgets_dates ON budgets (start_date, end_date);

-- Composite index for active budget lookup
CREATE INDEX idx_budgets_user_active_dates ON budgets (user_id, is_active, start_date, end_date);

-- Comments
COMMENT ON TABLE budgets IS 'Stores user budget limits for categories';
COMMENT ON COLUMN budgets.category_id IS 'NULL for overall budget, category_id for category-specific budget';
COMMENT ON COLUMN budgets.period_type IS 'Budget period: WEEKLY, BIWEEKLY, MONTHLY, QUARTERLY, YEARLY, CUSTOM';
COMMENT ON COLUMN budgets.alert_threshold IS 'Percentage (0-100) at which to trigger budget alert';
