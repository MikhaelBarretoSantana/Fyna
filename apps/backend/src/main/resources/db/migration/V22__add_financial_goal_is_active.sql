-- ============================================
-- FYNA - Finance AI Application
-- Migration V22: Soft-delete para metas financeiras
-- ============================================
-- Migra `deleteGoal` de hard-delete para soft-delete, em linha com Account,
-- Budget, Category e RecurringTransaction. Preserva histórico para
-- notificações já emitidas (que apontam para /goals/{id}).

ALTER TABLE financial_goals ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE;

CREATE INDEX idx_financial_goals_user_active ON financial_goals (user_id, is_active);

COMMENT ON COLUMN financial_goals.is_active IS
    'FALSE indica meta arquivada (soft-delete). Queries de listagem devem filtrar por TRUE.';
