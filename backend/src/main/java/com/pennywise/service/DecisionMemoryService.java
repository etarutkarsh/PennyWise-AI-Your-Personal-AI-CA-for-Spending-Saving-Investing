package com.pennywise.service;

import com.pennywise.dto.memory.*;
import com.pennywise.engine.memory.DecisionMemoryEngine;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.DecisionOutcome;
import com.pennywise.entity.User;
import com.pennywise.repository.DecisionMemoryRepository;
import com.pennywise.repository.DecisionOutcomeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class DecisionMemoryService {

    private final CurrentUserProvider currentUserProvider;
    private final DecisionMemoryRepository memoryRepository;
    private final DecisionOutcomeRepository outcomeRepository;
    private final DecisionMemoryEngine memoryEngine;

    public List<DecisionMemoryDto> listAll() {
        User user = currentUserProvider.get();
        List<DecisionMemory> memories = memoryEngine.timeline(user.getId());
        return memories.stream().map(m -> toDto(m, outcomeRepository.findByDecisionId(m.getId()).orElse(null))).toList();
    }

    public DecisionMemoryDto getById(UUID id) {
        User user = currentUserProvider.get();
        DecisionMemory m = memoryRepository.findById(id)
            .filter(dm -> dm.getUserId().equals(user.getId()))
            .orElseThrow(() -> new RuntimeException("Decision memory not found"));
        DecisionOutcome outcome = outcomeRepository.findByDecisionId(id).orElse(null);
        return toDto(m, outcome);
    }

    public DecisionOutcomeDto submitReview(UUID id, ReviewRequest req) {
        User user = currentUserProvider.get();
        DecisionMemory memory = memoryRepository.findById(id)
            .filter(dm -> dm.getUserId().equals(user.getId()))
            .orElseThrow(() -> new RuntimeException("Decision memory not found"));
        DecisionOutcome outcome = memoryEngine.submitReview(memory, req, user.getId());
        return toOutcomeDto(outcome);
    }

    public List<TimelineEntryDto> timeline() {
        User user = currentUserProvider.get();
        List<DecisionMemory> memories = memoryEngine.timeline(user.getId());
        return memories.stream().map(m -> {
            DecisionOutcome o = outcomeRepository.findByDecisionId(m.getId()).orElse(null);
            return TimelineEntryDto.builder()
                .id(m.getId())
                .itemName(m.getItemName())
                .itemPrice(m.getItemPrice())
                .recommendation(m.getRecommendation())
                .recommendationStrength(m.getRecommendationStrength())
                .reviewAfter(m.getReviewAfter())
                .status(m.getStatus())
                .createdAt(m.getCreatedAt())
                .followedRecommendation(o != null ? o.getFollowedRecommendation() : null)
                .accuracyScore(o != null ? o.getAccuracyScore() : null)
                .build();
        }).toList();
    }

    public List<DecisionMemoryDto> pendingReviews() {
        User user = currentUserProvider.get();
        return memoryEngine.pendingReviews(user.getId()).stream()
            .map(m -> toDto(m, null)).toList();
    }

    public InsightsDto insights() {
        User user = currentUserProvider.get();
        return memoryEngine.computeInsights(user.getId());
    }

    private DecisionMemoryDto toDto(DecisionMemory m, DecisionOutcome outcome) {
        return DecisionMemoryDto.builder()
            .id(m.getId())
            .decisionType(m.getDecisionType())
            .itemName(m.getItemName())
            .itemPrice(m.getItemPrice())
            .recommendation(m.getRecommendation())
            .recommendationStrength(m.getRecommendationStrength())
            .reviewAfter(m.getReviewAfter())
            .status(m.getStatus())
            .createdAt(m.getCreatedAt())
            .recommendationEvidence(m.getRecommendationEvidence())
            .recommendedScenario(m.getRecommendedScenario())
            .alternatives(m.getAlternatives())
            .goalImpacts(m.getGoalImpacts())
            .behaviorSnapshot(m.getBehaviorSnapshot())
            .outcome(outcome != null ? toOutcomeDto(outcome) : null)
            .build();
    }

    private DecisionOutcomeDto toOutcomeDto(DecisionOutcome o) {
        return DecisionOutcomeDto.builder()
            .id(o.getId())
            .actualChoice(o.getActualChoice())
            .followedRecommendation(o.getFollowedRecommendation())
            .notes(o.getNotes())
            .reviewedAt(o.getReviewedAt())
            .goalDelta(o.getGoalDelta())
            .healthDelta(o.getHealthDelta())
            .accuracyScore(o.getAccuracyScore())
            .lessons(o.getLessons())
            .build();
    }
}
