-- ============================================
-- FYNA - Finance AI Application
-- Migration V18: Create Triggers for Updated At
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for user_preferences table
CREATE TRIGGER trg_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for accounts table
CREATE TRIGGER trg_accounts_updated_at
    BEFORE UPDATE ON accounts
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for categories table
CREATE TRIGGER trg_categories_updated_at
    BEFORE UPDATE ON categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for transactions table
CREATE TRIGGER trg_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for recurring_transactions table
CREATE TRIGGER trg_recurring_transactions_updated_at
    BEFORE UPDATE ON recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for budgets table
CREATE TRIGGER trg_budgets_updated_at
    BEFORE UPDATE ON budgets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for financial_goals table
CREATE TRIGGER trg_financial_goals_updated_at
    BEFORE UPDATE ON financial_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger for risk_profiles table
CREATE TRIGGER trg_risk_profiles_updated_at
    BEFORE UPDATE ON risk_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
