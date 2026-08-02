package com.pennywise.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.dto.twin.DigitalTwinDto;
import com.pennywise.dto.twin.GoalTrajectoryDto;
import com.pennywise.dto.twin.ProjectionPointDto;
import com.pennywise.engine.twin.*;
import com.pennywise.entity.FinancialDigitalTwin;
import com.pennywise.repository.FinancialDigitalTwinRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Manages the Financial Digital Twin lifecycle for a user.
 *
 * <p>Caching strategy: the twin is recomputed when missing or older than 6 hours.
 * A force-refresh bypasses the TTL check and always recomputes.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class DigitalTwinService {

    private static final int STALENESS_HOURS = 6;

    private final CurrentUserProvider currentUserProvider;
    private final FinancialDigitalTwinEngine twinEngine;
    private final FinancialDigitalTwinRepository twinRepository;
    private final ObjectMapper objectMapper;

    /**
     * Returns the current user's digital twin, recomputing if stale (>6h) or missing.
     */
    @Transactional
    public DigitalTwinDto getTwin() {
        UUID userId = currentUserProvider.get().getId();
        Optional<FinancialDigitalTwin> existing = twinRepository.findByUserId(userId);

        if (existing.isEmpty() || isStale(existing.get())) {
            log.info("DigitalTwinService: twin missing or stale for userId={}, recomputing", userId);
            return computeAndPersist(userId);
        }

        log.debug("DigitalTwinService: returning cached twin for userId={}", userId);
        return toDto(existing.get());
    }

    /**
     * Forces an immediate recomputation of the twin, ignoring the 6-hour TTL.
     */
    @Transactional
    public DigitalTwinDto refreshTwin() {
        UUID userId = currentUserProvider.get().getId();
        log.info("DigitalTwinService: forced refresh for userId={}", userId);
        return computeAndPersist(userId);
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private DigitalTwinDto computeAndPersist(UUID userId) {
        TwinSnapshot snapshot = twinEngine.compute(userId);
        FinancialDigitalTwin entity = persist(userId, snapshot);
        return toDto(entity);
    }

    private FinancialDigitalTwin persist(UUID userId, TwinSnapshot snap) {
        FinancialDigitalTwin entity = twinRepository.findByUserId(userId)
                .orElseGet(() -> {
                    FinancialDigitalTwin t = new FinancialDigitalTwin();
                    t.setUserId(userId);
                    return t;
                });

        entity.setTwinScore(snap.getTwinScore());
        entity.setNetWorth(snap.getNetWorth());
        entity.setTotalAssets(snap.getTotalAssets());
        entity.setTotalLiabilities(snap.getTotalLiabilities());
        entity.setMonthlyIncome(snap.getMonthlyIncome());
        entity.setMonthlyExpenses(snap.getMonthlyExpenses());
        entity.setMonthlySurplus(snap.getMonthlySurplus());
        entity.setEfCoverageMonths(snap.getEfCoverageMonths());
        entity.setDtiRatio(snap.getDtiRatio());
        entity.setBehaviorFactor(java.math.BigDecimal.valueOf(snap.getBehaviorFactor())
                .setScale(4, java.math.RoundingMode.HALF_UP));
        entity.setLastComputedAt(LocalDateTime.now());

        // Store projections at key milestones
        snap.getProjectionSeries().stream()
                .filter(p -> p.getMonthsFromNow() == 12)
                .findFirst()
                .ifPresent(p -> entity.setProjection12m(p.getNetWorth()));
        snap.getProjectionSeries().stream()
                .filter(p -> p.getMonthsFromNow() == 36)
                .findFirst()
                .ifPresent(p -> entity.setProjection3yr(p.getNetWorth()));
        snap.getProjectionSeries().stream()
                .filter(p -> p.getMonthsFromNow() == 60)
                .findFirst()
                .ifPresent(p -> entity.setProjection5yr(p.getNetWorth()));
        snap.getProjectionSeries().stream()
                .filter(p -> p.getMonthsFromNow() == 120)
                .findFirst()
                .ifPresent(p -> entity.setProjection10yr(p.getNetWorth()));

        // Serialize goal trajectories and projection series to JSON TEXT
        entity.setGoalTrajectories(serializeGoalTrajectories(snap.getGoalTrajectories()));
        entity.setProjectionSeries(serializeProjectionSeries(snap.getProjectionSeries()));

        return twinRepository.save(entity);
    }

    boolean isStale(FinancialDigitalTwin twin) {
        return twin.getLastComputedAt() == null
                || twin.getLastComputedAt().isBefore(LocalDateTime.now().minusHours(STALENESS_HOURS));
    }

    private DigitalTwinDto toDto(FinancialDigitalTwin entity) {
        List<GoalTrajectoryDto> goals = deserializeGoalTrajectories(entity.getGoalTrajectories());
        List<ProjectionPointDto> projections = deserializeProjectionSeries(entity.getProjectionSeries());

        double behaviorFactor = entity.getBehaviorFactor() != null
                ? entity.getBehaviorFactor().doubleValue()
                : 0.75;

        return DigitalTwinDto.builder()
                .twinScore(entity.getTwinScore())
                .netWorth(entity.getNetWorth())
                .totalAssets(entity.getTotalAssets())
                .totalLiabilities(entity.getTotalLiabilities())
                .monthlyIncome(entity.getMonthlyIncome())
                .monthlyExpenses(entity.getMonthlyExpenses())
                .monthlySurplus(entity.getMonthlySurplus())
                .efCoverageMonths(entity.getEfCoverageMonths())
                .dtiRatio(entity.getDtiRatio())
                .behaviorFactor(behaviorFactor)
                .projection12m(entity.getProjection12m())
                .projection3yr(entity.getProjection3yr())
                .projection5yr(entity.getProjection5yr())
                .projection10yr(entity.getProjection10yr())
                .goalTrajectories(goals)
                .projectionSeries(projections)
                .dataQuality(dataQualityFor(entity.getTwinScore()))
                .build();
    }

    private String dataQualityFor(int score) {
        if (score >= 80) return "COMPLETE";
        if (score >= 50) return "GOOD";
        return "BASIC";
    }

    // ── JSON serialization helpers ────────────────────────────────────────────

    private String serializeGoalTrajectories(List<GoalTrajectory> trajectories) {
        if (trajectories == null || trajectories.isEmpty()) return "[]";
        try {
            List<GoalTrajectoryDto> dtos = trajectories.stream()
                    .map(this::trajectoryToDto)
                    .toList();
            return objectMapper.writeValueAsString(dtos);
        } catch (Exception e) {
            log.warn("DigitalTwinService: failed to serialize goal trajectories: {}", e.getMessage());
            return "[]";
        }
    }

    private String serializeProjectionSeries(List<ProjectionPoint> series) {
        if (series == null || series.isEmpty()) return "[]";
        try {
            List<ProjectionPointDto> dtos = series.stream()
                    .map(p -> ProjectionPointDto.builder()
                            .monthsFromNow(p.getMonthsFromNow())
                            .netWorth(p.getNetWorth())
                            .cumulativeSavings(p.getCumulativeSavings())
                            .build())
                    .toList();
            return objectMapper.writeValueAsString(dtos);
        } catch (Exception e) {
            log.warn("DigitalTwinService: failed to serialize projection series: {}", e.getMessage());
            return "[]";
        }
    }

    private List<GoalTrajectoryDto> deserializeGoalTrajectories(String json) {
        if (json == null || json.isBlank() || json.equals("[]")) return Collections.emptyList();
        try {
            return objectMapper.readValue(json, new TypeReference<List<GoalTrajectoryDto>>() {});
        } catch (Exception e) {
            log.warn("DigitalTwinService: failed to deserialize goal trajectories: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private List<ProjectionPointDto> deserializeProjectionSeries(String json) {
        if (json == null || json.isBlank() || json.equals("[]")) return Collections.emptyList();
        try {
            return objectMapper.readValue(json, new TypeReference<List<ProjectionPointDto>>() {});
        } catch (Exception e) {
            log.warn("DigitalTwinService: failed to deserialize projection series: {}", e.getMessage());
            return Collections.emptyList();
        }
    }

    private GoalTrajectoryDto trajectoryToDto(GoalTrajectory t) {
        String deadlineIso = t.getDeadline() != null ? t.getDeadline().toString() : null;
        String deadlineFormatted = formatDeadline(t.getDeadline());
        return GoalTrajectoryDto.builder()
                .goalId(t.getGoalId())
                .goalName(t.getGoalName())
                .targetAmount(t.getTargetAmount())
                .currentSaved(t.getCurrentSaved())
                .deadline(deadlineIso)
                .deadlineFormatted(deadlineFormatted)
                .completionProbability(t.getCompletionProbability())
                .monthsToCompletion(t.getMonthsToCompletion())
                .onTrack(t.isOnTrack())
                .status(t.getStatus())
                .build();
    }

    private String formatDeadline(LocalDate date) {
        if (date == null) return null;
        return date.format(DateTimeFormatter.ofPattern("MMM yyyy"));
    }
}
