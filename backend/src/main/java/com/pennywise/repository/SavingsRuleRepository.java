package com.pennywise.repository;

import com.pennywise.entity.SavingsRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SavingsRuleRepository extends JpaRepository<SavingsRule, UUID> {

    List<SavingsRule> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
