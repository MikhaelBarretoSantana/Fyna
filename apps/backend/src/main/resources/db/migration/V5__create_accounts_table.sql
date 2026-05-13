-- ============================================
-- FYNA - Finance AI Application
-- Migration V5: Create Accounts Table
-- ============================================

CREATE TABLE accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    name VARCHAR(100) NOT NULL,
    type VARCHAR(30) NOT NULL,
    institution VARCHAR(100),
    color VARCHAR(7),
    icon VARCHAR(50),
    initial_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    current_balance DECIMAL(15, 2) NOT NULL DEFAULT 0.00,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    include_in_total BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_accounts_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_accounts_type CHECK (type IN (
        'CHECKING', 'SAVINGS', 'CREDIT_CARD', 'CASH', 
        'INVESTMENT', 'DIGITAL_WALLET', 'OTHER'
    ))
);

-- Indexes
CREATE INDEX idx_accounts_user_id ON accounts (user_id);
CREATE INDEX idx_accounts_type ON accounts (type);
CREATE INDEX idx_accounts_is_active ON accounts (is_active);

-- Comments
COMMENT ON TABLE accounts IS 'Stores user financial accounts';
COMMENT ON COLUMN accounts.type IS 'Account type: CHECKING, SAVINGS, CREDIT_CARD, CASH, INVESTMENT, DIGITAL_WALLET, OTHER';
COMMENT ON COLUMN accounts.color IS 'Hex color code for UI display (e.g., #FF5733)';
COMMENT ON COLUMN accounts.include_in_total IS 'Whether to include this account in total balance calculations';
