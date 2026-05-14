-- Idempotência para gatilhos de notificação.
-- budgets.last_alert_threshold: maior percentual já notificado (0, threshold, 100).
--   Evita reenviar BUDGET_ALERT enquanto o consumo permanecer na mesma faixa.
-- financial_goals.last_progress_milestone: maior marco percentual já notificado (0, 50, 75, 100).
--   Evita reenviar GOAL_PROGRESS / GOAL_COMPLETED em cada nova contribuição.

ALTER TABLE budgets
    ADD COLUMN last_alert_threshold NUMERIC(5, 2) NOT NULL DEFAULT 0;

ALTER TABLE financial_goals
    ADD COLUMN last_progress_milestone SMALLINT NOT NULL DEFAULT 0;
