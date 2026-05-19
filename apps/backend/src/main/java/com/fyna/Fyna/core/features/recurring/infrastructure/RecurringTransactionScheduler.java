package com.fyna.Fyna.core.features.recurring.infrastructure;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import com.fyna.Fyna.core.features.recurring.domain.service.RecurringTransactionService;

/**
 * Dispara o processamento de transações recorrentes diariamente.
 *
 * <p>Roda às 00:05 (horário do servidor) para garantir que toda recorrente
 * com {@code nextOccurrence <= today} gere a transação correspondente,
 * atualize saldo e consumo de orçamento. Requer {@code @EnableScheduling}
 * na aplicação (já habilitado em {@code FynaApplication}).
 */
@Component
public class RecurringTransactionScheduler {

    private static final Logger log = LoggerFactory.getLogger(RecurringTransactionScheduler.class);

    private final RecurringTransactionService recurringTransactionService;

    public RecurringTransactionScheduler(RecurringTransactionService recurringTransactionService) {
        this.recurringTransactionService = recurringTransactionService;
    }

    /** Processa recorrentes pendentes uma vez por dia. */
    @Scheduled(cron = "0 5 0 * * *")
    public void dailyProcess() {
        log.info("Iniciando processamento diário de transações recorrentes");
        try {
            recurringTransactionService.processRecurringTransactions();
            log.info("Processamento diário de transações recorrentes concluído");
        } catch (Exception e) {
            log.error("Falha ao processar transações recorrentes: {}", e.getMessage(), e);
        }
    }
}
