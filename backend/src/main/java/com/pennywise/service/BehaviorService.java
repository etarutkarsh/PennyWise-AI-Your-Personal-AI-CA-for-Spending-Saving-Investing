package com.pennywise.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.dto.behavior.BehaviorProfileDto;
import com.pennywise.engine.behavioral.BehavioralEngine;
import com.pennywise.entity.BehaviorProfile;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.FinancialEvent;
import com.pennywise.entity.User;
import com.pennywise.repository.BehaviorProfileRepository;
import com.pennywise.repository.DecisionMemoryRepository;
import com.pennywise.repository.FinancialEventRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class BehaviorService {

    private final CurrentUserProvider currentUserProvider;
    private final BehaviorProfileRepository profileRepository;
    private final FinancialEventRepository eventRepository;
    private final DecisionMemoryRepository decisionRepository;
    private final BehavioralEngine behavioralEngine;
    private final ObjectMapper objectMapper;

    /**
     * Returns the current user's behavioral profile, recomputing if stale (> 24 hours old).
     */
    public BehaviorProfileDto getProfile() {
        User user = currentUserProvider.get();
        Optional<BehaviorProfile> existing = profileRepository.findByUserId(user.getId());

        if (existing.isEmpty() || isStale(existing.get())) {
            log.info("BehaviorService: profile missing or stale for userId={}, recomputing", user.getId());
            return computeAndReturn(user);
        }
        return toDto(existing.get());
    }

    /**
     * Forces recomputation of the behavioral profile regardless of staleness.
     */
    public BehaviorProfileDto recomputeProfile() {
        User user = currentUserProvider.get();
        log.info("BehaviorService: forced recompute for userId={}", user.getId());
        return computeAndReturn(user);
    }

    private BehaviorProfileDto computeAndReturn(User user) {
        List<FinancialEvent> events = eventRepository.findByUserId(user.getId());
        List<DecisionMemory> decisions = decisionRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        BehaviorProfile profile = behavioralEngine.computeAndSave(user.getId(), events, decisions);
        return toDto(profile);
    }

    private boolean isStale(BehaviorProfile profile) {
        return profile.getLastComputedAt() == null ||
                profile.getLastComputedAt().isBefore(Instant.now().minus(24, ChronoUnit.HOURS));
    }

    private BehaviorProfileDto toDto(BehaviorProfile p) {
        String discipline = parseTraitGrade(p.getTraitsJson(), "discipline");
        String impulseControl = parseTraitGrade(p.getTraitsJson(), "impulseControl");
        String goalCommitment = parseTraitGrade(p.getTraitsJson(), "goalCommitment");
        String savingsConsistency = parseTraitGrade(p.getTraitsJson(), "savingsConsistency");
        String riskBehavior = classifyRiskLabel(p.getRiskBehaviorScore());

        List<String> insights = parseJsonArray(p.getInsightsJson());
        List<String> detectedPatterns = parseJsonArray(p.getDetectedPatterns());

        String dataConfidence;
        if (p.getMonthsOfData() >= 6) {
            dataConfidence = "HIGH";
        } else if (p.getMonthsOfData() >= 3) {
            dataConfidence = "MEDIUM";
        } else {
            dataConfidence = "LOW";
        }

        return BehaviorProfileDto.builder()
                .discipline(discipline)
                .impulseControl(impulseControl)
                .goalCommitment(goalCommitment)
                .savingsConsistency(savingsConsistency)
                .riskBehavior(riskBehavior)
                .primaryBehavior(p.getPrimaryBehavior())
                .secondaryBehavior(p.getSecondaryBehavior())
                .followRate(p.getRecommendationFollowRate())
                .disciplineScore(p.getDisciplineScore())
                .insights(insights)
                .detectedPatterns(detectedPatterns)
                .eventsAnalyzed(p.getEventsAnalyzed())
                .decisionsAnalyzed(p.getDecisionsAnalyzed())
                .monthsOfData(p.getMonthsOfData())
                .dataConfidence(dataConfidence)
                .lastUpdated(p.getLastComputedAt())
                .build();
    }

    private String parseTraitGrade(String traitsJson, String key) {
        if (traitsJson == null || traitsJson.isBlank()) return "C-";
        try {
            java.util.Map<String, String> traits = objectMapper.readValue(
                    traitsJson, new TypeReference<java.util.Map<String, String>>() {});
            return traits.getOrDefault(key, "C-");
        } catch (Exception e) {
            log.debug("BehaviorService: could not parse traitsJson key={}: {}", key, e.getMessage());
            return "C-";
        }
    }

    private List<String> parseJsonArray(String json) {
        if (json == null || json.isBlank()) return Collections.emptyList();
        try {
            return objectMapper.readValue(json, new TypeReference<List<String>>() {});
        } catch (Exception e) {
            log.debug("BehaviorService: could not parse JSON array: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private String classifyRiskLabel(int riskBehaviorScore) {
        if (riskBehaviorScore >= 70) return "Conservative";
        if (riskBehaviorScore >= 45) return "Moderate";
        return "Aggressive";
    }
}
