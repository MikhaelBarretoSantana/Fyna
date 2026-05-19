-- ============================================
-- FYNA - Finance AI Application
-- Migration V23: Modelar conta destino em recorrentes do tipo TRANSFER
-- ============================================
-- Sem essa coluna, a perna destino da transferência recorrente nunca era
-- gerada — o saldo da conta receptora ficava parado enquanto a origem era
-- debitada todo mês. Coluna nullable (recorrentes INCOME/EXPENSE seguem
-- usando apenas account_id).

ALTER TABLE recurring_transactions
    ADD COLUMN transfer_account_id UUID;

ALTER TABLE recurring_transactions
    ADD CONSTRAINT fk_recurring_transactions_transfer_account
        FOREIGN KEY (transfer_account_id) REFERENCES accounts(id) ON DELETE SET NULL;

ALTER TABLE recurring_transactions
    ADD CONSTRAINT chk_recurring_transactions_transfer_different_account
        CHECK (transfer_account_id IS NULL OR transfer_account_id <> account_id);

ALTER TABLE recurring_transactions
    ADD CONSTRAINT chk_recurring_transactions_transfer_account_required
        CHECK (type <> 'TRANSFER' OR transfer_account_id IS NOT NULL);

CREATE INDEX idx_recurring_transactions_transfer_account_id
    ON recurring_transactions (transfer_account_id);

COMMENT ON COLUMN recurring_transactions.transfer_account_id IS
    'Conta destino para recorrentes do tipo TRANSFER. NULL para INCOME/EXPENSE.';
