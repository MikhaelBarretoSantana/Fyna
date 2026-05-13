-- ============================================
-- FYNA - Finance AI Application
-- Migration V8: Create Transactions Table
-- ============================================

CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    account_id UUID NOT NULL,
    category_id UUID,
    transfer_pair_id UUID,
    type VARCHAR(20) NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    description VARCHAR(255) NOT NULL,
    notes TEXT,
    transaction_date DATE NOT NULL,
    due_date DATE,
    is_paid BOOLEAN NOT NULL DEFAULT TRUE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurring_transaction_id UUID,
    attachment_url VARCHAR(500),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_account FOREIGN KEY (account_id) 
        REFERENCES accounts(id) ON DELETE CASCADE,
    CONSTRAINT fk_transactions_category FOREIGN KEY (category_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT fk_transactions_transfer_pair FOREIGN KEY (transfer_pair_id) 
        REFERENCES transactions(id) ON DELETE SET NULL,
    CONSTRAINT fk_transactions_recurring FOREIGN KEY (recurring_transaction_id) 
        REFERENCES recurring_transactions(id) ON DELETE SET NULL,
    CONSTRAINT chk_transactions_type CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER')),
    CONSTRAINT chk_transactions_amount CHECK (amount > 0)
);

-- Indexes
CREATE INDEX idx_transactions_user_id ON transactions (user_id);
CREATE INDEX idx_transactions_account_id ON transactions (account_id);
CREATE INDEX idx_transactions_category_id ON transactions (category_id);
CREATE INDEX idx_transactions_type ON transactions (type);
CREATE INDEX idx_transactions_transaction_date ON transactions (transaction_date);
CREATE INDEX idx_transactions_due_date ON transactions (due_date);
CREATE INDEX idx_transactions_is_paid ON transactions (is_paid);
CREATE INDEX idx_transactions_recurring_id ON transactions (recurring_transaction_id);
CREATE INDEX idx_transactions_transfer_pair_id ON transactions (transfer_pair_id);

-- Composite indexes for common queries
CREATE INDEX idx_transactions_user_date ON transactions (user_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_account_date ON transactions (user_id, account_id, transaction_date DESC);
CREATE INDEX idx_transactions_user_category_date ON transactions (user_id, category_id, transaction_date DESC);

-- Comments
COMMENT ON TABLE transactions IS 'Stores all financial transactions';
COMMENT ON COLUMN transactions.transfer_pair_id IS 'Links two transactions that form a transfer between accounts';
COMMENT ON COLUMN transactions.is_recurring IS 'TRUE if this transaction was generated from a recurring template';
COMMENT ON COLUMN transactions.metadata IS 'Additional JSON data (tags, location, etc.)';
