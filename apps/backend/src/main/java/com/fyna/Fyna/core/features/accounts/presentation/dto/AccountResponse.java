package com.fyna.Fyna.core.features.accounts.presentation.dto;

import java.math.BigDecimal;
import java.util.UUID;

import com.fyna.Fyna.core.shared.domain.Accounts;
import com.fyna.Fyna.core.shared.enums.AccountTypes;

public record AccountResponse(
        UUID id,
        String name,
        AccountTypes type,
        String institution,
        String color,
        String icon,
        BigDecimal initialBalance,
        BigDecimal currentBalance,
        boolean isActive,
        boolean includeInTotal
) {
    public static AccountResponse from(Accounts account) {
        return new AccountResponse(
                account.getId(),
                account.getName(),
                account.getType(),
                account.getInstitution(),
                account.getColor(),
                account.getIcon(),
                account.getInitialBalance(),
                account.getCurrentBalance(),
                account.getIsActive(),
                account.getIncludeInTotal()
        );
    }
}
