package com.fyna.Fyna.core.features.users.presentation.dto;

import java.time.Instant;
import java.util.List;

import com.fyna.Fyna.core.features.accounts.presentation.dto.AccountResponse;
import com.fyna.Fyna.core.features.budgets.presentation.dto.BudgetResponse;
import com.fyna.Fyna.core.features.categories.presentation.dto.CategoryResponse;
import com.fyna.Fyna.core.features.goals.presentation.dto.FinancialGoalResponse;
import com.fyna.Fyna.core.features.transactions.presentation.dto.TransactionResponse;

/**
 * Pacote completo de dados pessoais do titular para fins de
 * portabilidade (art. 18, V, da LGPD).
 *
 * Estrutura plana, em JSON, com timestamp de geração e versão do
 * formato — para permitir importação por outro sistema sem
 * dependência de schema interno do Fyna.
 */
public record UserDataExportResponse(
        String exportFormatVersion,
        Instant generatedAt,
        UserResponse user,
        UserPreferencesResponse preferences,
        List<AccountResponse> accounts,
        List<CategoryResponse> categories,
        List<TransactionResponse> transactions,
        List<BudgetResponse> budgets,
        List<FinancialGoalResponse> goals
) {
    public static final String FORMAT_VERSION = "1.0";
}
