package com.pennywise.engine.memory;

import com.pennywise.dto.memory.*;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.DecisionOutcome;
import com.pennywise.repository.DecisionMemoryRepository;
import com.pennywise.repository.DecisionOutcomeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.*;

@Slf4j
@Component
@RequiredArgsConstructor
public class DecisionMemoryEngine {

    private final DecisionMemoryRepository memoryRepository;
    private final DecisionOutcomeRepository outcomeRepository;
    private final DecisionOutcomeEngine outcomeEngine;

    public List<DecisionMemory> timeline(UUID userId) {
        return memoryRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<DecisionMemory> pendingReviews(UUID userId) {
        return memoryRepository.findPendingReviews(userId, LocalDate.now());
    }

    public DecisionOutcome submitReview(DecisionMemory memory, ReviewRequest req, UUID userId) {
        DecisionOutcome outcome = outcomeEngine.recordOutcome(memory, req);
        memory.setStatus("REVIEWED");
        memoryRepository.save(memory);
        return outcome;
    }

    public InsightsDto computeInsights(UUID userId) {
        List<DecisionMemory> all = memoryRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<UUID> ids = all.stream().map(DecisionMemory::getId).toList();
        List<DecisionOutcome> outcomes = ids.isEmpty() ? List.of()
            : outcomeRepository.findByDecisionIdIn(ids);

        long total = all.size();
        long reviewed = outcomes.size();
        long followed = outcomes.stream().filter(o -> Boolean.TRUE.equals(o.getFollowedRecommendation())).count();
        double followRate = reviewed > 0 ? (double) followed / reviewed * 100 : 0;

        Double avgAccuracy = memoryRepository.avgAccuracyByUserId(userId);

        // Behavioral observations
        List<String> observations = new ArrayList<>();
        if (total > 0) {
            observations.add("You have made " + total + " recorded financial decision" + (total == 1 ? "" : "s") + " with PennyWise.");
        }
        if (reviewed > 0) {
            observations.add(String.format("You followed %.0f%% of PennyWise recommendations you reviewed.", followRate));
        }
        if (avgAccuracy != null) {
            observations.add(String.format("Recommendation accuracy across reviewed decisions: %.1f%%.", avgAccuracy));
        }
        long pending = memoryRepository.countByUserIdAndStatus(userId, "PENDING_REVIEW");
        if (pending > 0) {
            observations.add("You have " + pending + " decision" + (pending == 1 ? "" : "s") + " awaiting review.");
        }

        return InsightsDto.builder()
            .totalDecisions((int) total)
            .reviewedDecisions((int) reviewed)
            .followRate(Math.round(followRate * 10.0) / 10.0)
            .averageAccuracy(avgAccuracy != null ? Math.round(avgAccuracy * 10.0) / 10.0 : null)
            .pendingReviews((int) pending)
            .observations(observations)
            .build();
    }
}
