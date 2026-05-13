package com.fyna.Fyna.core.features.categories.data.repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.fyna.Fyna.core.shared.domain.Categories;
import com.fyna.Fyna.core.shared.enums.CategoriesTypes;

@Repository
public interface CategoryRepository extends JpaRepository<Categories, UUID> {

    List<Categories> findByUserIdAndIsActiveTrue(UUID userId);

    List<Categories> findByUserIsNullAndIsSystemTrueAndIsActiveTrue();

    List<Categories> findByUserIdOrUserIsNull(UUID userId);

    Optional<Categories> findByIdAndUserId(UUID id, UUID userId);

    List<Categories> findByParentIdAndIsActiveTrue(UUID parentId);

    List<Categories> findByTypeAndIsActiveTrue(CategoriesTypes type);

    List<Categories> findByUserIdAndTypeAndIsActiveTrue(UUID userId, CategoriesTypes type);
}
