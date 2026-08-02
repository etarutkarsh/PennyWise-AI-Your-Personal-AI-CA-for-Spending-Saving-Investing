package com.pennywise.engine.behavioral;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.entity.BehaviorProfile;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.FinancialEvent;
import com.pennywise.repository.BehaviorProfileRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.*;

/**
 * Orchestrates all behavioral sub-engines to produce a complete {@link BehaviorProfile}.
 * <p>
 * Execution order:
 * 1. DisciplineEngine  — decision follow-through analysis
 * 2. SpendingPsychologyEngine — spending pattern detection
 * 3. HabitEngine — goal and budget habit analysis
 * 4. RiskBehaviorEngine — risk profile from snapshots
 * 5. BehaviorInsightEngine — insights, traits, classifications
 * 6. Upsert BehaviorProfile to DB
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BehavioralEngine {

    private final BehaviorProfileRepository profileRepository;
    private final DisciplineEngine disciplineEngine;
    private final SpendingPsychologyEngine spendingEngine;
    private final HabitEngine habitEngine;
    private final RiskBehaviorEngine riskEngine;
    private final BehaviorInsightEngine insightEngine;
    private final ObjectMapper objectMapper;

    @Transactional
    public BehaviorProfile computeAndSave(UUID userId,
                                           List<FinancialEvent> events,
                                           List<DecisionMemory> decisions) {
        log.info("BehavioralEngine: computing profile for userId={} events={} decisions={}",
                userId, events.size(), decisions.size());

        // Run sub-engines
        DisciplineEngine.DisciplineResult disciplineResult = disciplineEngine.analyze(userId, decisions);
        SpendingPsychologyEngine.SpendingResult spendingResult = spendingEngine.analyze(userId, events);
        HabitEngine.HabitResult habitResult = habitEngine.analyze(userId, events);
        RiskBehaviorEngine.RiskResult riskResult = riskEngine.analyze(userId, events, decisions);

        // Merge all detected patterns
        Set<BehaviorPattern> allPatterns = new HashSet<>();
        allPatterns.addAll(disciplineResult.patterns());
        allPatterns.addAll(spendingResult.patterns());
        allPatterns.addAll(habitResult.patterns());
        allPatterns.addAll(riskResult.patterns());

        // Compute months of data
        int monthsOfData = computeMonthsOfData(events, decisions);

        // Build consolidated BehaviorScores
        BehaviorScores scores = BehaviorScores.builder()
                .disciplineScore(normalize(disciplineResult.disciplineScore()))
                .consistencyScore(normalize(riskResult.consistencyScore()))
                .impulseScore(normalize(spendingResult.impulseScore()))
                .riskBehaviorScore(normalize(riskResult.riskBehaviorScore()))
                .goalCommitmentScore(normalize(habitResult.goalCommitmentScore()))
                .savingsDisciplineScore(normalize(habitResult.savingsDisciplineScore()))
                .spendingStabilityScore(normalize(spendingResult.spendingStabilityScore()))
                .recommendationFollowRate(normalize(disciplineResult.recommendationFollowRate()))
                .patterns(allPatterns)
                .eventsAnalyzed(events.size())
                .decisionsAnalyzed(decisions.size())
                .monthsOfData(monthsOfData)
                .build();

        // Generate insights and traits
        List<String> insights = insightEngine.generateInsights(scores);
        Map<String, String> traits = insightEngine.computeTraits(scores);
        String primaryBehavior = insightEngine.classifyPrimaryBehavior(scores);
        String secondaryBehavior = insightEngine.classifySecondaryBehavior(scores);

        // Serialize JSON fields
        String detectedPatternsJson = serializeToJson(allPatterns.stream()
                .map(BehaviorPattern::name).toList());
        String traitsJson = serializeToJson(traits);
        String insightsJson = serializeToJson(insights);

        // Upsert BehaviorProfile
        BehaviorProfile profile = profileRepository.findByUserId(userId)
                .orElseGet(() -> {
                    BehaviorProfile p = new BehaviorProfile();
                    p.setUserId(userId);
                    return p;
                });

        profile.setDisciplineScore(scores.getDisciplineScore());
        profile.setConsistencyScore(scores.getConsistencyScore());
        profile.setImpulseScore(scores.getImpulseScore());
        profile.setRiskBehaviorScore(scores.getRiskBehaviorScore());
        profile.setGoalCommitmentScore(scores.getGoalCommitmentScore());
        profile.setSavingsDisciplineScore(scores.getSavingsDisciplineScore());
        profile.setSpendingStabilityScore(scores.getSpendingStabilityScore());
        profile.setRecommendationFollowRate(scores.getRecommendationFollowRate());
        profile.setDetectedPatterns(detectedPatternsJson);
        profile.setTraitsJson(traitsJson);
        profile.setInsightsJson(insightsJson);
        profile.setPrimaryBehavior(primaryBehavior);
        profile.setSecondaryBehavior(secondaryBehavior);
        profile.setEventsAnalyzed(events.size());
        profile.setDecisionsAnalyzed(decisions.size());
        profile.setMonthsOfData(monthsOfData);
        profile.setLastComputedAt(Instant.now());

        BehaviorProfile saved = profileRepository.save(profile);
        log.info("BehavioralEngine: saved profile id={} for userId={} primary='{}'",
                saved.getId(), userId, primaryBehavior);
        return saved;
    }

    /** Normalize a score to [0, 100]. */
    private int normalize(int score) {
        return Math.min(100, Math.max(0, score));
    }

    private int computeMonthsOfData(List<FinancialEvent> events, List<DecisionMemory> decisions) {
        Set<String> months = new HashSet<>();
        events.forEach(e -> months.add(e.getOccurredAt().toString().substring(0, 7)));
        decisions.forEach(d -> months.add(d.getCreatedAt().toString().substring(0, 7)));
        return months.size();
    }

    private String serializeToJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (Exception e) {
            log.warn("BehavioralEngine: failed to serialize JSON: {}", e.getMessage());
            return "[]";
        }
    }
}
