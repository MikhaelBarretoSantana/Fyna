package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fyna.Fyna.core.shared.enums.AccountTypes;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

@Entity
@Table(name = "accounts", indexes = {
    @Index(name = "idx_accounts_user_id", columnList = "user"),
    @Index(name = "idx_accounts_type", columnList = "type"),
    @Index(name = "idx_accounts_is_active", columnList = "is_active")
})
public class Accounts extends AbstractAuditingEntity<UUID> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties(value = "accounts", allowSetters = true)
    private User user;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false)
    private AccountTypes type;

    @Column(name = "institution", length = 100)
    private String institution;

    @Column(name = "color", length = 7)
    private String color;

    @Column(name = "icon", length = 50)
    private String icon;

    @Column(name = "initial_balance", nullable = false, precision = 15, scale = 2)
    private BigDecimal initialBalance = BigDecimal.ZERO;

    @Column(name = "current_balance", nullable = false, precision = 15, scale = 2)
    private BigDecimal currentBalance = BigDecimal.ZERO;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "include_in_total", nullable = false)
    private Boolean includeInTotal = true;

    public Accounts() {
    }

    public Accounts(UUID id, User user, String name, AccountTypes type, String institution, String color, String icon,
            BigDecimal initialBalance, BigDecimal currentBalance, Boolean isActive, Boolean includeInTotal) {
        this.id = id;
        this.user = user;
        this.name = name;
        this.type = type;
        this.institution = institution;
        this.color = color;
        this.icon = icon;
        this.initialBalance = initialBalance;
        this.currentBalance = currentBalance;
        this.isActive = isActive;
        this.includeInTotal = includeInTotal;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public AccountTypes getType() {
        return type;
    }

    public void setType(AccountTypes type) {
        this.type = type;
    }

    public String getInstitution() {
        return institution;
    }

    public void setInstitution(String institution) {
        this.institution = institution;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public BigDecimal getInitialBalance() {
        return initialBalance;
    }

    public void setInitialBalance(BigDecimal initialBalance) {
        this.initialBalance = initialBalance;
    }

    public BigDecimal getCurrentBalance() {
        return currentBalance;
    }

    public void setCurrentBalance(BigDecimal currentBalance) {
        this.currentBalance = currentBalance;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public Boolean getIncludeInTotal() {
        return includeInTotal;
    }

    public void setIncludeInTotal(Boolean includeInTotal) {
        this.includeInTotal = includeInTotal;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((user == null) ? 0 : user.hashCode());
        result = prime * result + ((name == null) ? 0 : name.hashCode());
        result = prime * result + ((type == null) ? 0 : type.hashCode());
        result = prime * result + ((institution == null) ? 0 : institution.hashCode());
        result = prime * result + ((color == null) ? 0 : color.hashCode());
        result = prime * result + ((icon == null) ? 0 : icon.hashCode());
        result = prime * result + ((initialBalance == null) ? 0 : initialBalance.hashCode());
        result = prime * result + ((currentBalance == null) ? 0 : currentBalance.hashCode());
        result = prime * result + ((isActive == null) ? 0 : isActive.hashCode());
        result = prime * result + ((includeInTotal == null) ? 0 : includeInTotal.hashCode());
        return result;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj)
            return true;
        if (obj == null)
            return false;
        if (getClass() != obj.getClass())
            return false;
        Accounts other = (Accounts) obj;
        if (id == null) {
            if (other.id != null)
                return false;
        } else if (!id.equals(other.id))
            return false;
        if (user == null) {
            if (other.user != null)
                return false;
        } else if (!user.equals(other.user))
            return false;
        if (name == null) {
            if (other.name != null)
                return false;
        } else if (!name.equals(other.name))
            return false;
        if (type != other.type)
            return false;
        if (institution == null) {
            if (other.institution != null)
                return false;
        } else if (!institution.equals(other.institution))
            return false;
        if (color == null) {
            if (other.color != null)
                return false;
        } else if (!color.equals(other.color))
            return false;
        if (icon == null) {
            if (other.icon != null)
                return false;
        } else if (!icon.equals(other.icon))
            return false;
        if (initialBalance == null) {
            if (other.initialBalance != null)
                return false;
        } else if (!initialBalance.equals(other.initialBalance))
            return false;
        if (currentBalance == null) {
            if (other.currentBalance != null)
                return false;
        } else if (!currentBalance.equals(other.currentBalance))
            return false;
        if (isActive == null) {
            if (other.isActive != null)
                return false;
        } else if (!isActive.equals(other.isActive))
            return false;
        if (includeInTotal == null) {
            if (other.includeInTotal != null)
                return false;
        } else if (!includeInTotal.equals(other.includeInTotal))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "Accounts [id=" + id + ", user=" + user + ", name=" + name + ", type=" + type + ", institution="
                + institution + ", color=" + color + ", icon=" + icon + ", initialBalance=" + initialBalance
                + ", currentBalance=" + currentBalance + ", isActive=" + isActive + ", includeInTotal=" + includeInTotal
                + "]";
    }

}
