package com.fyna.Fyna.core.shared.domain;

import java.util.UUID;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

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
@Table(name = "categories", indexes = {
        @Index(name = "idx_categories_user_id", columnList = "user_id"),
        @Index(name = "idx_categories_parent_id", columnList = "parent_id"),
        @Index(name = "idx_categories_type", columnList = "type"),
        @Index(name = "idx_categories_is_system", columnList = "is_system"),
        @Index(name = "idx_categories_is_active", columnList = "is_active"),
})
public class Categories extends AbstractAuditingEntity<UUID> {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "user_id")
    @JsonIgnoreProperties(value = "categories", allowSetters = true)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = true)
    @JoinColumn(name = "parent_id")
    @JsonIgnoreProperties(value = "categories", allowSetters = true)
    private Categories parent;

    @Column(name = "name", length = 100, nullable = false)
    private String name;

    @Column(name = "icon", length = 50)
    private String icon;

    @Column(name = "color", length = 7)
    private String color;

    @Enumerated(EnumType.STRING)
    @Column(name = "type", length = 20, nullable = false)
    private CategoriesTypes type;

    @Column(name = "is_system", nullable = false)
    private Boolean isSystem = false;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "display_order", nullable = false)
    private int displayOrder = 0;

    public Categories() {
    }

    public Categories(UUID id, User user, Categories parent, String name, String icon, String color,
            CategoriesTypes type, Boolean isSystem, Boolean isActive, int displayOrder) {
        this.id = id;
        this.user = user;
        this.parent = parent;
        this.name = name;
        this.icon = icon;
        this.color = color;
        this.type = type;
        this.isSystem = isSystem;
        this.isActive = isActive;
        this.displayOrder = displayOrder;
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

    public Categories getParent() {
        return parent;
    }

    public void setParent(Categories parent) {
        this.parent = parent;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getIcon() {
        return icon;
    }

    public void setIcon(String icon) {
        this.icon = icon;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public CategoriesTypes getType() {
        return type;
    }

    public void setType(CategoriesTypes type) {
        this.type = type;
    }

    public Boolean getIsSystem() {
        return isSystem;
    }

    public void setIsSystem(Boolean isSystem) {
        this.isSystem = isSystem;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    @Override
    public int hashCode() {
        final int prime = 31;
        int result = 1;
        result = prime * result + ((id == null) ? 0 : id.hashCode());
        result = prime * result + ((user == null) ? 0 : user.hashCode());
        result = prime * result + ((parent == null) ? 0 : parent.hashCode());
        result = prime * result + ((name == null) ? 0 : name.hashCode());
        result = prime * result + ((icon == null) ? 0 : icon.hashCode());
        result = prime * result + ((color == null) ? 0 : color.hashCode());
        result = prime * result + ((type == null) ? 0 : type.hashCode());
        result = prime * result + ((isSystem == null) ? 0 : isSystem.hashCode());
        result = prime * result + ((isActive == null) ? 0 : isActive.hashCode());
        result = prime * result + displayOrder;
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
        Categories other = (Categories) obj;
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
        if (parent == null) {
            if (other.parent != null)
                return false;
        } else if (!parent.equals(other.parent))
            return false;
        if (name == null) {
            if (other.name != null)
                return false;
        } else if (!name.equals(other.name))
            return false;
        if (icon == null) {
            if (other.icon != null)
                return false;
        } else if (!icon.equals(other.icon))
            return false;
        if (color == null) {
            if (other.color != null)
                return false;
        } else if (!color.equals(other.color))
            return false;
        if (type != other.type)
            return false;
        if (isSystem == null) {
            if (other.isSystem != null)
                return false;
        } else if (!isSystem.equals(other.isSystem))
            return false;
        if (isActive == null) {
            if (other.isActive != null)
                return false;
        } else if (!isActive.equals(other.isActive))
            return false;
        if (displayOrder != other.displayOrder)
            return false;
        return true;
    }

    @Override
    public String toString() {
        return "Categories [id=" + id + ", user=" + user + ", parent=" + parent + ", name=" + name + ", icon=" + icon
                + ", color=" + color + ", type=" + type + ", isSystem=" + isSystem + ", isActive=" + isActive
                + ", displayOrder=" + displayOrder + "]";
    }

}
