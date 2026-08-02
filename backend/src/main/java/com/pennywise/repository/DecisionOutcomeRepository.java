package com.pennywise.repository;

import com.pennywise.entity.DecisionOutcome;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DecisionOutcomeRepository extends JpaRepository<DecisionOutcome, UUID> {
    Optional<DecisionOutcome> findByDecisionId(UUID decisionId);
    List<DecisionOutcome> findByDecisionIdIn(List<UUID> decisionIds);
}
