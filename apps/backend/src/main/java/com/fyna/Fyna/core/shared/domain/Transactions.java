package com.fyna.Fyna.core.shared.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

import com.fyna.Fyna.core.shared.enums.TransactionsType;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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
@Table(name = "transactions", indexes = {
        @Index(name = "idx_transactions_user_id", columnList = "user_id"),
        @Index(name = "idx_transactions_account_id", columnList = "account_id"),
        @Index(name = "idx_transactions_category_id", columnList = "category_id"),
        @Index(name = "idx_transactions_type", columnList = "type"),
        @Index(name = "idx_transactions_transaction_date", columnList = "transaction_date"),
        @Index(name = "idx_transactions_due_date", columnList = "due_date"),
        @Index(name = "idx_transactions_is_paid", columnList = "is_paid"),
        @Index(name = "idx_transactions_recurring_id", columnList = "recurring_transaction_id"),
        @Index(name = "idx_transactions_transfer_pair_id", columnList = "transfer_pair_id"),
        @Index(name = "idx_transactions_user_date", columnList = "user_id,transaction_date DESC"),
        @Index(name = "idx_transactions_user_account_date", columnList = "user_id,account_id,transaction_date DESC"),
        @Index(name = "idx_transactions_user_category_date", columnList = "user_id,category_id,transaction_date DESC")
})
public class Transactions extends AbstractAuditingEntity<UUID> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "account_id")
    private Accounts account;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private Categories categories;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "transfer_pair_id")
    private Transactions transactions;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 20, nullable = false)
    private TransactionsType type;

    @Column(name = "amount", nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;

    @Column(name = "description", length = 255, nullable = false)
    private String description;

    @Column(name = "notes", columnDefinition = "TEXT")
    private String notes;

    @Column(name = "transaction_date", nullable = false)
    private LocalDate transactionDate;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "is_paid", nullable = false)
    private Boolean isPaid = true;

    @Column(name = "is_recurring", nullable = false)
    private Boolean isRecurring = false;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recurring_transaction_id")
    private RecurringTransactions recurringTransactions;

    @Column(name = "attachment_url", length = 500)
    private String attachmentUrl;

    @Column(name = "metadata", columnDefinition = "jsonb")
    @JdbcTypeCode(SqlTypes.JSON)
    private String metadata;

    public Transactions() {
    }

    public Transactions(UUID id, User user, Accounts account, Categories categories, Transactions transactions,
            TransactionsType type, BigDecimal amount, String description, String notes, LocalDate transactionDate,
            LocalDate dueDate, Boolean isPaid, Boolean isRecurring, RecurringTransactions recurringTransactions,
            String attachmentUrl, String metadata) {
        this.id = id;
        this.user = user;
        this.account = account;
        this.categories = categories;
        this.transactions = transactions;
        this.type = type;
        this.amount = amount;
        this.description = description;
        this.notes = notes;
        this.transactionDate = transactionDate;
        this.dueDate = dueDate;
        this.isPaid = isPaid;
        this.isRecurring = isRecurring;
        this.recurringTransactions = recurringTransactions;
        this.attachmentUrl = attachmentUrl;
        this.metadata = metadata;
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

    public Transactions getTransactions() {
        return transactions;
    }

    public void setTransactions(Transactions transactions) {
        this.transactions = transactions;
    }

    public TransactionsType getType() {
        return type;
    }

    public void setType(TransactionsType type) {
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

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public LocalDate getTransactionDate() {
        return transactionDate;
    }

    public void setTransactionDate(LocalDate transactionDate) {
        this.transactionDate = transactionDate;
    }

    public LocalDate getDueDate() {
        return dueDate;
    }

    public void setDueDate(LocalDate dueDate) {
        this.dueDate = dueDate;
    }

    public Boolean getIsPaid() {
        return isPaid;
    }

    public void setIsPaid(Boolean isPaid) {
        this.isPaid = isPaid;
    }

    public Boolean getIsRecurring() {
        return isRecurring;
    }

    public void setIsRecurring(Boolean isRecurring) {
        this.isRecurring = isRecurring;
    }

    public RecurringTransactions getRecurringTransactions() {
        return recurringTransactions;
    }

    public void setRecurringTransactions(RecurringTransactions recurringTransactions) {
        this.recurringTransactions = recurringTransactions;
    }

    public String getAttachmentUrl() {
        return attachmentUrl;
    }

    public void setAttachmentUrl(String attachmentUrl) {
        this.attachmentUrl = attachmentUrl;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((user == null) ? 0 : user.hashCode());
        result = prime * result + ((account == null) ? 0 : account.hashCode());
        result = prime * result + ((categories == null) ? 0 : categories.hashCode());
        result = prime * result + ((transactions == null) ? 0 : transactions.hashCode());
        result = prime * result + ((type == null) ? 0 : type.hashCode());
        result = prime * result + ((amount == null) ? 0 : amount.hashCode());
        result = prime * result + ((description == null) ? 0 : description.hashCode());
        result = prime * result + ((notes == null) ? 0 : notes.hashCode());
        result = prime * result + ((transactionDate == null) ? 0 : transactionDate.hashCode());
        result = prime * result + ((dueDate == null) ? 0 : dueDate.hashCode());
        result = prime * result + ((isPaid == null) ? 0 : isPaid.hashCode());
        result = prime * result + ((isRecurring == null) ? 0 : isRecurring.hashCode());
        result = prime * result + ((recurringTransactions == null) ? 0 : recurringTransactions.hashCode());
        result = prime * result + ((attachmentUrl == null) ? 0 : attachmentUrl.hashCode());
        result = prime * result + ((metadata == null) ? 0 : metadata.hashCode());
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
        Transactions other = (Transactions) obj;
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
        if (transactions == null) {
            if (other.transactions != null)
                return false;
        } else if (!transactions.equals(other.transactions))
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
        if (notes == null) {
            if (other.notes != null)
                return false;
        } else if (!notes.equals(other.notes))
            return false;
        if (transactionDate == null) {
            if (other.transactionDate != null)
                return false;
        } else if (!transactionDate.equals(other.transactionDate))
            return false;
        if (dueDate == null) {
            if (other.dueDate != null)
                return false;
        } else if (!dueDate.equals(other.dueDate))
            return false;
        if (isPaid == null) {
            if (other.isPaid != null)
                return false;
        } else if (!isPaid.equals(other.isPaid))
            return false;
        if (isRecurring == null) {
            if (other.isRecurring != null)
                return false;
        } else if (!isRecurring.equals(other.isRecurring))
            return false;
        if (recurringTransactions == null) {
            if (other.recurringTransactions != null)
                return false;
        } else if (!recurringTransactions.equals(other.recurringTransactions))
            return false;
        if (attachmentUrl == null) {
            if (other.attachmentUrl != null)
                return false;
        } else if (!attachmentUrl.equals(other.attachmentUrl))
            return false;
        if (metadata == null) {
            if (other.metadata != null)
                return false;
        } else if (!metadata.equals(other.metadata))
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "Transactions [id=" + id + ", user=" + user + ", account=" + account + ", categories=" + categories
                + ", transactions=" + transactions + ", type=" + type + ", amount=" + amount + ", description="
                + description + ", notes=" + notes + ", transactionDate=" + transactionDate + ", dueDate=" + dueDate
                + ", isPaid=" + isPaid + ", isRecurring=" + isRecurring + ", recurringTransactions="
                + recurringTransactions + ", attachmentUrl=" + attachmentUrl + ", metadata=" + metadata + "]";
    }

}
