-- ============================================
-- FYNA - Finance AI Application
-- Migration V21: Track current rolling period for periodic budgets
-- ============================================
-- Adds `current_period_start` so WEEKLY/BIWEEKLY/MONTHLY/QUARTERLY/YEARLY
-- budgets reset `amount_spent` and `last_alert_threshold` automatically
-- when a period boundary is crossed. CUSTOM budgets ignore this column.

ALTER TABLE budgets ADD COLUMN current_period_start DATE;
UPDATE budgets SET current_period_start = start_date WHERE current_period_start IS NULL;
ALTER TABLE budgets ALTER COLUMN current_period_start SET NOT NULL;
ALTER TABLE budgets ALTER COLUMN current_period_start SET DEFAULT CURRENT_DATE;

COMMENT ON COLUMN budgets.current_period_start IS
    'Início do ciclo corrente para budgets periódicos. Avança a cada rollover; '
    'amount_spent e last_alert_threshold zeram quando o ciclo vira.';
