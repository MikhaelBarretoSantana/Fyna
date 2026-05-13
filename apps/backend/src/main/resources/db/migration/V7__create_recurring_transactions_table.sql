-- ============================================
-- FYNA - Finance AI Application
-- Migration V7: Create Recurring Transactions Table
-- ============================================

CREATE TABLE recurring_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    account_id UUID NOT NULL,
    category_id UUID,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    frequency VARCHAR(20) NOT NULL,
    frequency_interval INTEGER NOT NULL DEFAULT 1,
    start_date DATE NOT NULL,
    end_date DATE,
    next_occurrence DATE NOT NULL,
    last_generated DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_recurring_transactions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_recurring_transactions_account FOREIGN KEY (account_id) 
        REFERENCES accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_recurring_transactions_category FOREIGN KEY (category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT chk_recurring_transactions_type CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER')),
    CONSTRAINT chk_recurring_transactions_frequency CHECK (frequency IN (
        'DAILY', 'WEEKLY', 'BIWEEKLY', 'MONTHLY', 'BIMONTHLY', 
        'QUARTERLY', 'SEMIANNUALLY', 'ANNUALLY'
    )),
    CONSTRAINT chk_recurring_transactions_interval CHECK (frequency_interval > 0),
    CONSTRAINT chk_recurring_transactions_amount CHECK (amount > 0)
);

-- Indexes
CREATE INDEX idx_recurring_transactions_user_id ON recurring_transactions (user_id);
CREATE INDEX idx_recurring_transactions_account_id ON recurring_transactions (account_id);
CREATE INDEX idx_recurring_transactions_category_id ON recurring_transactions (category_id);
CREATE INDEX idx_recurring_transactions_next_occurrence ON recurring_transactions (next_occurrence);
CREATE INDEX idx_recurring_transactions_is_active ON recurring_transactions (is_active);

-- Comments
COMMENT ON TABLE recurring_transactions IS 'Stores recurring transaction templates';
COMMENT ON COLUMN recurring_transactions.frequency IS 'Recurrence frequency: DAILY, WEEKLY, BIWEEKLY, MONTHLY, etc.';
COMMENT ON COLUMN recurring_transactions.frequency_interval IS 'Interval multiplier (e.g., 2 for every 2 weeks)';
COMMENT ON COLUMN recurring_transactions.next_occurrence IS 'Next date when transaction should be generated';
