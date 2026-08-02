package com.pennywise.engine.behavioral;

import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.DecisionOutcome;
import com.pennywise.repository.DecisionMemoryRepository;
import com.pennywise.repository.DecisionOutcomeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Analyzes decision memory records to compute discipline-related scores.
 * <p>
 * Discipline score = how consistently the user follows recommendations.
 * Uses both proxy metrics (reviewed / total) and actual outcome data when available.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class DisciplineEngine {

    private final DecisionMemoryRepository decisionMemoryRepository;
    private final DecisionOutcomeRepository decisionOutcomeRepository;

    public record DisciplineResult(
            int disciplineScore,
            int recommendationFollowRate,
            Set<BehaviorPattern> patterns
    ) {}

    public DisciplineResult analyze(UUID userId, List<DecisionMemory> decisions) {
        if (decisions.isEmpty()) {
            return new DisciplineResult(50, 0, Set.of());
        }

        long total = decisions.size();
        long reviewed = decisions.stream()
                .filter(d -> "REVIEWED".equals(d.getStatus()))
                .count();

        // Compute actual follow rate from DecisionOutcome records when available
        List<UUID> reviewedIds = decisions.stream()
                .filter(d -> "REVIEWED".equals(d.getStatus()))
                .map(DecisionMemory::getId)
                .collect(Collectors.toList());

        int followRate;
        int disciplineScore;

        if (!reviewedIds.isEmpty()) {
            List<DecisionOutcome> outcomes = decisionOutcomeRepository.findByDecisionIdIn(reviewedIds);
            if (!outcomes.isEmpty()) {
                long followed = outcomes.stream()
                        .filter(o -> Boolean.TRUE.equals(o.getFollowedRecommendation()))
                        .count();
                followRate = (int) Math.round(followed * 100.0 / outcomes.size());
                // Discipline = follow rate (60%) + review rate proxy (40%)
                int reviewRate = (int) Math.round(reviewed * 100.0 / total);
                disciplineScore = (int) Math.round(followRate * 0.6 + reviewRate * 0.4);
            } else {
                // Have reviewed records but no outcome data yet — use review rate as proxy
                followRate = (int) Math.round(reviewed * 100.0 / total);
                disciplineScore = followRate;
            }
        } else {
            // No reviews yet — neutral score
            followRate = 0;
            disciplineScore = 50;
        }

        disciplineScore = Math.min(100, Math.max(0, disciplineScore));
        followRate = Math.min(100, Math.max(0, followRate));

        Set<BehaviorPattern> patterns = new HashSet<>();
        // Pattern detection requires minimum 2 reviewed decisions to avoid false positives
        if (reviewed >= 2) {
            if (followRate >= 80) {
                patterns.add(BehaviorPattern.DISCIPLINED_FOLLOWER);
            } else if (followRate < 40 && reviewed >= 2) {
                patterns.add(BehaviorPattern.RECOMMENDATION_RESISTANT);
            }
        }

        log.debug("DisciplineEngine: userId={} total={} reviewed={} followRate={} disciplineScore={}",
                userId, total, reviewed, followRate, disciplineScore);

        return new DisciplineResult(disciplineScore, followRate, patterns);
    }
}
