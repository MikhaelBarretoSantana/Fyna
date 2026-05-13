-- ============================================
-- FYNA - Finance AI Application
-- Migration V6: Create Categories Table
-- ============================================

CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    parent_id UUID,
    name VARCHAR(100) NOT NULL,
    icon VARCHAR(50),
    color VARCHAR(7),
    type VARCHAR(20) NOT NULL,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_categories_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id) 
        REFERENCES categories(id) ON DELETE SET NULL,
    CONSTRAINT chk_categories_type CHECK (type IN ('INCOME', 'EXPENSE', 'TRANSFER'))
);

-- Indexes
CREATE INDEX idx_categories_user_id ON categories (user_id);
CREATE INDEX idx_categories_parent_id ON categories (parent_id);
CREATE INDEX idx_categories_type ON categories (type);
CREATE INDEX idx_categories_is_system ON categories (is_system);
CREATE INDEX idx_categories_is_active ON categories (is_active);

-- Comments
COMMENT ON TABLE categories IS 'Stores transaction categories (system and user-defined)';
COMMENT ON COLUMN categories.user_id IS 'NULL for system categories, user_id for custom categories';
COMMENT ON COLUMN categories.parent_id IS 'Parent category for subcategories';
COMMENT ON COLUMN categories.type IS 'Category type: INCOME, EXPENSE, or TRANSFER';
COMMENT ON COLUMN categories.is_system IS 'TRUE for default system categories that cannot be deleted';
