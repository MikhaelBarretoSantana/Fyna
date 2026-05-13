-- ============================================
-- FYNA - Finance AI Application
-- Migration V4: Create User Preferences Table
-- ============================================

CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    currency VARCHAR(3) NOT NULL DEFAULT 'BRL',
    locale VARCHAR(10) NOT NULL DEFAULT 'pt-BR',
    timezone VARCHAR(50) NOT NULL DEFAULT 'America/Sao_Paulo',
    theme VARCHAR(20) NOT NULL DEFAULT 'SYSTEM',
    push_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    email_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    budget_alerts BOOLEAN NOT NULL DEFAULT TRUE,
    weekly_summary BOOLEAN NOT NULL DEFAULT TRUE,
    ai_suggestions BOOLEAN NOT NULL DEFAULT TRUE,
    first_day_of_week INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uk_user_preferences_user_id UNIQUE (user_id),
    CONSTRAINT fk_user_preferences_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT chk_user_preferences_theme CHECK (theme IN ('LIGHT', 'DARK', 'SYSTEM')),
    CONSTRAINT chk_user_preferences_first_day CHECK (first_day_of_week BETWEEN 0 AND 6)
);

-- Index
CREATE INDEX idx_user_preferences_user_id ON user_preferences (user_id);

-- Comments
COMMENT ON TABLE user_preferences IS 'Stores user preferences and settings';
COMMENT ON COLUMN user_preferences.currency IS 'Preferred currency code (ISO 4217)';
COMMENT ON COLUMN user_preferences.locale IS 'Preferred locale for formatting';
COMMENT ON COLUMN user_preferences.first_day_of_week IS 'First day of week: 0=Sunday, 1=Monday, etc.';
