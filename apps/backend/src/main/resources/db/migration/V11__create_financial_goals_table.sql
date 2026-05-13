-- ============================================
-- FYNA - Finance AI Application
-- Migration V11: Create Financial Goals Table
-- ============================================

CREATE TABLE financial_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(50),
    color VARCHAR(7),
    target_amount DECIMAL(15, 2) NOT NULL,
    current_amount DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    target_date DATE,
    status VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    priority VARCHAR(10) NOT NULL DEFAULT 'MEDIUM',
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_financial_goals_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_financial_goals_status CHECK (status IN (
        'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'PAUSED'
    )),
    CONSTRAINT chk_financial_goals_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH')),
    CONSTRAINT chk_financial_goals_target_amount CHECK (target_amount > 0),
    CONSTRAINT chk_financial_goals_current_amount CHECK (current_amount >= 0)
);

-- Indexes
CREATE INDEX idx_financial_goals_user_id ON financial_goals (user_id);
CREATE INDEX idx_financial_goals_status ON financial_goals (status);
CREATE INDEX idx_financial_goals_priority ON financial_goals (priority);
CREATE INDEX idx_financial_goals_target_date ON financial_goals (target_date);

-- Composite index for dashboard queries
CREATE INDEX idx_financial_goals_user_status ON financial_goals (user_id, status);

-- Comments
COMMENT ON TABLE financial_goals IS 'Stores user financial goals and savings targets';
COMMENT ON COLUMN financial_goals.status IS 'Goal status: IN_PROGRESS, COMPLETED, CANCELLED, PAUSED';
COMMENT ON COLUMN financial_goals.priority IS 'Goal priority: LOW, MEDIUM, HIGH';
COMMENT ON COLUMN financial_goals.current_amount IS 'Current amount saved towards the goal';
