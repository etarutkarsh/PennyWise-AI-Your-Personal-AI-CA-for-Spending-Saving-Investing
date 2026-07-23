package com.pennywise.repository;

import com.pennywise.entity.Budget;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetRepository extends JpaRepository<Budget, UUID> {

    List<Budget> findByUserIdAndPeriod(UUID userId, String period);

    Optional<Budget> findByUserIdAndCategoryIdAndPeriod(UUID userId, UUID categoryId, String period);
}
