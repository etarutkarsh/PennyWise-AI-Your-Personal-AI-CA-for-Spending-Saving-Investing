package com.pennywise.engine.memory;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.dto.memory.ReviewRequest;
import com.pennywise.entity.DecisionMemory;
import com.pennywise.entity.DecisionOutcome;
import com.pennywise.repository.DecisionOutcomeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class DecisionOutcomeEngine {

    private final DecisionOutcomeRepository outcomeRepository;
    private final DecisionAccuracyEngine accuracyEngine;
    private final ObjectMapper objectMapper;

    public DecisionOutcome recordOutcome(DecisionMemory memory, ReviewRequest req) {
        boolean followed = Boolean.TRUE.equals(req.getFollowedRecommendation());

        List<String> lessons = accuracyEngine.deriveLessons(
            followed, req.getHealthDelta(), memory.getRecommendation(), memory.getItemName());

        DecisionOutcome outcome = new DecisionOutcome();
        outcome.setDecisionId(memory.getId());
        outcome.setActualChoice(req.getActualChoice());
        outcome.setFollowedRecommendation(followed);
        outcome.setNotes(req.getNotes());
        outcome.setReviewedAt(LocalDate.now());
        outcome.setGoalDelta(req.getGoalDelta());
        outcome.setHealthDelta(req.getHealthDelta());
        outcome.setAccuracyScore(accuracyEngine.computeOverallAccuracy(
            followed, req.getHealthDelta(),
            inferPredictedHealthDelta(memory.getRecommendation())));
        try {
            outcome.setLessons(objectMapper.writeValueAsString(lessons));
        } catch (Exception e) {
            log.warn("Could not serialize lessons", e);
        }
        return outcomeRepository.save(outcome);
    }

    private int inferPredictedHealthDelta(String recommendation) {
        return switch (recommendation) {
            case "SAFE_TO_BUY" -> 2;
            case "WAIT_AND_SAVE" -> 8;   // waiting improves health
            case "DONT_BUY" -> 10;
            default -> 0;
        };
    }
}
