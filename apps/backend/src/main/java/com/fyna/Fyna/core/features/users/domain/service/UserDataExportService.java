package com.fyna.Fyna.core.features.users.domain.service;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.stream.Stream;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fyna.Fyna.core.exception.ResourceNotFoundException;
import com.fyna.Fyna.core.features.accounts.data.repository.AccountRepository;
import com.fyna.Fyna.core.features.accounts.presentation.dto.AccountResponse;
import com.fyna.Fyna.core.features.auth.data.repository.UserRepository;
import com.fyna.Fyna.core.features.budgets.data.repository.BudgetRepository;
import com.fyna.Fyna.core.features.budgets.presentation.dto.BudgetResponse;
import com.fyna.Fyna.core.features.categories.data.repository.CategoryRepository;
import com.fyna.Fyna.core.features.categories.presentation.dto.CategoryResponse;
import com.fyna.Fyna.core.features.goals.data.repository.FinancialGoalRepository;
import com.fyna.Fyna.core.features.goals.presentation.dto.FinancialGoalResponse;
import com.fyna.Fyna.core.features.transactions.data.repository.TransactionRepository;
import com.fyna.Fyna.core.features.transactions.presentation.dto.TransactionResponse;
import com.fyna.Fyna.core.features.users.data.repository.UserPreferencesRepository;
import com.fyna.Fyna.core.features.users.presentation.dto.UserDataExportResponse;
import com.fyna.Fyna.core.features.users.presentation.dto.UserPreferencesResponse;
import com.fyna.Fyna.core.features.users.presentation.dto.UserResponse;
import com.fyna.Fyna.core.shared.domain.User;

/**
 * Atende ao direito de portabilidade previsto no art. 18, inciso V, da LGPD:
 * entrega ao titular cópia estruturada de todos os seus dados pessoais
 * tratados pelo Fyna, em formato interoperável (JSON).
 *
 * Escopo do pacote:
 *   - Perfil do usuário e preferências.
 *   - Contas, transações, orçamentos e metas pertencentes ao titular.
 *   - Categorias do sistema (referência) + categorias customizadas do usuário.
 *
 * Fora de escopo desta versão:
 *   - Artefatos de IA (classificações, padrões, predições, recomendações)
 *     são considerados dados derivados; sua portabilidade exige discussão
 *     adicional sobre engenharia reversa do modelo. Mantido como trabalho
 *     futuro junto à exclusão em cascata.
 */
@Service
public class UserDataExportService {

    private final UserRepository userRepository;
    private final UserPreferencesRepository userPreferencesRepository;
    private final AccountRepository accountRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final FinancialGoalRepository financialGoalRepository;

    public UserDataExportService(UserRepository userRepository,
                                 UserPreferencesRepository userPreferencesRepository,
                                 AccountRepository accountRepository,
                                 CategoryRepository categoryRepository,
                                 TransactionRepository transactionRepository,
                                 BudgetRepository budgetRepository,
                                 FinancialGoalRepository financialGoalRepository) {
        this.userRepository = userRepository;
        this.userPreferencesRepository = userPreferencesRepository;
        this.accountRepository = accountRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.budgetRepository = budgetRepository;
        this.financialGoalRepository = financialGoalRepository;
    }

    @Transactional(readOnly = true)
    public UserDataExportResponse exportUserData(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", userId));

        UserPreferencesResponse preferences = userPreferencesRepository.findByUserId(userId)
                .map(UserPreferencesResponse::from)
                .orElse(null);

        List<AccountResponse> accounts = accountRepository.findByUserId(userId).stream()
                .map(AccountResponse::from)
                .toList();

        // Categorias visíveis ao usuário: as do sistema (sem user_id) + as customizadas
        List<CategoryResponse> categories = Stream.concat(
                categoryRepository.findByUserIsNullAndIsSystemTrueAndIsActiveTrue().stream(),
                categoryRepository.findByUserIdAndIsActiveTrue(userId).stream()
        ).map(CategoryResponse::from).toList();

        // Transações exportadas sem paginação — o titular tem direito ao conjunto completo.
        // Em volumes grandes, considerar streaming/NDJSON em versões futuras.
        List<TransactionResponse> transactions = transactionRepository
                .findByUserId(userId, org.springframework.data.domain.Pageable.unpaged())
                .map(TransactionResponse::from)
                .getContent();

        List<BudgetResponse> budgets = budgetRepository.findByUserId(userId).stream()
                .map(BudgetResponse::from)
                .toList();

        List<FinancialGoalResponse> goals = financialGoalRepository.findByUserIdAndIsActiveTrue(userId).stream()
                .map(FinancialGoalResponse::from)
                .toList();

        return new UserDataExportResponse(
                UserDataExportResponse.FORMAT_VERSION,
                Instant.now(),
                UserResponse.from(user),
                preferences,
                accounts,
                categories,
                transactions,
                budgets,
                goals
        );
    }
}
