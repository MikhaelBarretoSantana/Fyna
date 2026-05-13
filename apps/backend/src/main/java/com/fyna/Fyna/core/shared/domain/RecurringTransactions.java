package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.RecurringTransactionsFrequencyTypes;
import com.fyna.Fyna.core.shared.enums.RecurringTransactionsTypes;

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
@Table(name = "recurring_transactions", indexes = {
        @Index(name = "idx_recurring_transactions_user_id", columnList = "user_id"),
        @Index(name = "idx_recurring_transactions_account_id", columnList = "account_id"),
        @Index(name = "idx_recurring_transactions_category_id", columnList = "category_id"),
        @Index(name = "idx_recurring_transactions_next_occurrence", columnList = "next_occurrence"),
        @Index(name = "idx_recurring_transactions_is_active", columnList = "is_active"),

})
public class RecurringTransactions extends AbstractAuditingEntity<UUID> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id")
    private Accounts account;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "category_id")
    private Categories categories;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 20, nullable = false)
    private RecurringTransactionsTypes type;

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "description", length = 255, nullable = false)
    private String description;

    @Enumerated(EnumType.STRING)
    @Column(name = "frequency", nullable = false)
    private RecurringTransactionsFrequencyTypes frequency;

    @Column(name = "frequency_interval", nullable = false)
    private Integer frequencyInterval;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "next_occurrence", nullable = false)
    private LocalDate nextOccurrence;

    @Column(name = "last_generated")
    private LocalDate lastGenerated;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    public RecurringTransactions() {
    }

    public RecurringTransactions(UUID id, User user, Accounts account, Categories categories,
            RecurringTransactionsTypes type, BigDecimal amount, String description,
            RecurringTransactionsFrequencyTypes frequency, Integer frequencyInterval, LocalDate startDate,
            LocalDate endDate, LocalDate nextOccurrence, LocalDate lastGenerated, Boolean isActive) {
        this.id = id;
        this.user = user;
        this.account = account;
        this.categories = categories;
        this.type = type;
        this.amount = amount;
        this.description = description;
        this.frequency = frequency;
        this.frequencyInterval = frequencyInterval;
        this.startDate = startDate;
        this.endDate = endDate;
        this.nextOccurrence = nextOccurrence;
        this.lastGenerated = lastGenerated;
        this.isActive = isActive;
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

    public Accounts getAccount() {
        return account;
    }

    public void setAccount(Accounts account) {
        this.account = account;
    }

    public Categories getCategories() {
        return categories;
    }

    public void setCategories(Categories categories) {
        this.categories = categories;
    }

    public RecurringTransactionsTypes getType() {
        return type;
    }

    public void setType(RecurringTransactionsTypes type) {
        this.type = type;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public RecurringTransactionsFrequencyTypes getFrequency() {
        return frequency;
    }

    public void setFrequency(RecurringTransactionsFrequencyTypes frequency) {
        this.frequency = frequency;
    }

    public Integer getFrequencyInterval() {
        return frequencyInterval;
    }

    public void setFrequencyInterval(Integer frequencyInterval) {
        this.frequencyInterval = frequencyInterval;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public LocalDate getNextOccurrence() {
        return nextOccurrence;
    }

    public void setNextOccurrence(LocalDate nextOccurrence) {
        this.nextOccurrence = nextOccurrence;
    }

    public LocalDate getLastGenerated() {
        return lastGenerated;
    }

    public void setLastGenerated(LocalDate lastGenerated) {
        this.lastGenerated = lastGenerated;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((user == null) ? 0 : user.hashCode());
        result = prime * result + ((account == null) ? 0 : account.hashCode());
        result = prime * result + ((categories == null) ? 0 : categories.hashCode());
        result = prime * result + ((type == null) ? 0 : type.hashCode());
        result = prime * result + ((amount == null) ? 0 : amount.hashCode());
        result = prime * result + ((description == null) ? 0 : description.hashCode());
        result = prime * result + ((frequency == null) ? 0 : frequency.hashCode());
        result = prime * result + ((frequencyInterval == null) ? 0 : frequencyInterval.hashCode());
        result = prime * result + ((startDate == null) ? 0 : startDate.hashCode());
        result = prime * result + ((endDate == null) ? 0 : endDate.hashCode());
        result = prime * result + ((nextOccurrence == null) ? 0 : nextOccurrence.hashCode());
        result = prime * result + ((lastGenerated == null) ? 0 : lastGenerated.hashCode());
        result = prime * result + ((isActive == null) ? 0 : isActive.hashCode());
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
        RecurringTransactions other = (RecurringTransactions) obj;
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
        if (account == null) {
            if (other.account != null)
                return false;
        } else if (!account.equals(other.account))
            return false;
        if (categories == null) {
            if (other.categories != null)
                return false;
        } else if (!categories.equals(other.categories))
            return false;
        if (type != other.type)
            return false;
        if (amount == null) {
            if (other.amount != null)
                return false;
        } else if (!amount.equals(other.amount))
            return false;
        if (description == null) {
            if (other.description != null)
                return false;
        } else if (!description.equals(other.description))
            return false;
        if (frequency != other.frequency)
            return false;
        if (frequencyInterval == null) {
            if (other.frequencyInterval != null)
                return false;
        } else if (!frequencyInterval.equals(other.frequencyInterval))
            return false;
        if (startDate == null) {
            if (other.startDate != null)
                return false;
        } else if (!startDate.equals(other.startDate))
            return false;
        if (endDate == null) {
            if (other.endDate != null)
                return false;
        } else if (!endDate.equals(other.endDate))
            return false;
        if (nextOccurrence == null) {
            if (other.nextOccurrence != null)
                return false;
        } else if (!nextOccurrence.equals(other.nextOccurrence))
            return false;
        if (lastGenerated == null) {
            if (other.lastGenerated != null)
                return false;
        } else if (!lastGenerated.equals(other.lastGenerated))
            return false;
        if (isActive == null) {
            if (other.isActive != null)
                return false;
        } else if (!isActive.equals(other.isActive))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "RecurringTransactions [id=" + id + ", user=" + user + ", account=" + account + ", categories="
                + categories + ", type=" + type + ", amount=" + amount + ", description=" + description + ", frequency="
                + frequency + ", frequencyInterval=" + frequencyInterval + ", startDate=" + startDate + ", endDate="
                + endDate + ", nextOccurrence=" + nextOccurrence + ", lastGenerated=" + lastGenerated + ", isActive="
                + isActive + "]";
    }

}
