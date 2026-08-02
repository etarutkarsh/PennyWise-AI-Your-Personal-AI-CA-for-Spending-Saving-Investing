package com.pennywise.service;

import com.pennywise.dto.GoalCreateRequest;
import com.pennywise.dto.GoalDto;
import com.pennywise.dto.GoalUpdateRequest;
import com.pennywise.engine.events.EventBus;
import com.pennywise.engine.events.domain.GoalCompletedEvent;
import com.pennywise.engine.events.domain.GoalCreatedEvent;
import com.pennywise.entity.Goal;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.financial.engine.ProjectionEngine;
import com.pennywise.repository.GoalRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.UUID;

/**
 * Goal AI: computes the monthly contribution needed to hit a goal by its deadline,
 * and suggests an investment vehicle based on the time horizon.
 */
@Service
public class GoalService {

    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;
    private final ProjectionEngine projectionEngine;
    private final EventBus eventBus;

    public GoalService(GoalRepository goalRepository, CurrentUserProvider currentUserProvider,
                       ProjectionEngine projectionEngine, EventBus eventBus) {
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
        this.projectionEngine = projectionEngine;
        this.eventBus = eventBus;
    }

    @Transactional
    public GoalDto create(GoalCreateRequest request) {
        User user = currentUserProvider.get();

        Goal goal = new Goal();
        goal.setUserId(user.getId());
        goal.setName(request.getName());
        goal.setGoalType(request.getGoalType());
        goal.setTargetAmount(request.getTargetAmount());
        goal.setCurrentSaved(request.getCurrentSaved() != null ? request.getCurrentSaved() : BigDecimal.ZERO);
        goal.setDeadline(request.getDeadline());
        goal.setPriority(request.getPriority() != null ? request.getPriority() : "medium");

        applyRecommendation(goal);

        Goal saved = goalRepository.save(goal);
        eventBus.publish(new GoalCreatedEvent(user.getId(), saved.getId(), saved.getName(), saved.getTargetAmount()));
        return toDto(saved);
    }

    public List<GoalDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        return goalRepository.findByUserIdOrderByDeadlineAsc(user.getId())
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public GoalDto update(UUID goalId, GoalUpdateRequest request) {
        User user = currentUserProvider.get();
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));
        if (!goal.getUserId().equals(user.getId()))
            throw new ResourceNotFoundException("Goal not found");
        if (request.getName() != null) goal.setName(request.getName());
        if (request.getTargetAmount() != null) goal.setTargetAmount(request.getTargetAmount());
        if (request.getDeadline() != null) goal.setDeadline(request.getDeadline());
        if (request.getPriority() != null) goal.setPriority(request.getPriority());
        applyRecommendation(goal);
        return toDto(goalRepository.save(goal));
    }

    @Transactional
    public void delete(UUID goalId) {
        User user = currentUserProvider.get();
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));
        if (!goal.getUserId().equals(user.getId()))
            throw new ResourceNotFoundException("Goal not found");
        goalRepository.delete(goal);
    }

    public GoalDto updateSavedAmount(UUID goalId, BigDecimal newSavedAmount) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));
        boolean wasAchieved = goal.isAchieved();
        goal.setCurrentSaved(newSavedAmount);
        goal.setAchieved(newSavedAmount.compareTo(goal.getTargetAmount()) >= 0);
        applyRecommendation(goal);
        Goal saved = goalRepository.save(goal);
        if (!wasAchieved && saved.isAchieved()) {
            eventBus.publish(new GoalCompletedEvent(
                    saved.getUserId(), saved.getId(), saved.getName(), saved.getTargetAmount()));
        }
        return toDto(saved);
    }

    /**
     * Recomputes recommended monthly contribution + investment vehicle suggestion.
     *
     * Uses ProjectionEngine.goalMonthlyContribution() with a horizon-appropriate
     * expected return rate rather than simple division. This accounts for the
     * compounding benefit of investing the monthly contribution in a suitable instrument.
     */
    private void applyRecommendation(Goal goal) {
        long monthsRemaining = Math.max(1, Period.between(LocalDate.now(), goal.getDeadline()).toTotalMonths());
        BigDecimal shortfall = goal.getTargetAmount().subtract(goal.getCurrentSaved()).max(BigDecimal.ZERO);

        // Select expected return rate and investment vehicle based on time horizon.
        // Rates are conservative estimates aligned with the matching asset class.
        double annualReturnPercent;
        String suggestion;
        if (monthsRemaining <= 6) {
            annualReturnPercent = 5.5;  // LIQUID_FUND rate
            suggestion = "liquid_fund";
        } else if (monthsRemaining <= 18) {
            annualReturnPercent = 6.5;  // RD / ARBITRAGE rate
            suggestion = "rd";
        } else if (monthsRemaining <= 36) {
            annualReturnPercent = 7.0;  // DEBT_FUND / hybrid rate
            suggestion = "hybrid_fund";
        } else {
            annualReturnPercent = 11.5; // EQUITY_INDEX rate (Nifty50 long-term CAGR)
            suggestion = "equity";
        }

        double monthlyContributionDouble = projectionEngine.goalMonthlyContribution(
                shortfall.doubleValue(), annualReturnPercent, (int) monthsRemaining);

        BigDecimal monthlyContribution = BigDecimal.valueOf(monthlyContributionDouble)
                .setScale(0, RoundingMode.CEILING);

        goal.setRecommendedMonthlyContribution(monthlyContribution);
        goal.setInvestmentSuggestion(suggestion);
    }

    private GoalDto toDto(Goal g) {
        double progress = g.getTargetAmount().compareTo(BigDecimal.ZERO) > 0
                ? g.getCurrentSaved().divide(g.getTargetAmount(), 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).doubleValue()
                : 0.0;

        return GoalDto.builder()
                .id(g.getId())
                .name(g.getName())
                .goalType(g.getGoalType())
                .targetAmount(g.getTargetAmount())
                .currentSaved(g.getCurrentSaved())
                .deadline(g.getDeadline())
                .priority(g.getPriority())
                .recommendedMonthlyContribution(g.getRecommendedMonthlyContribution())
                .investmentSuggestion(g.getInvestmentSuggestion())
                .progressPercent(Math.min(100.0, progress))
                .achieved(g.isAchieved())
                .build();
    }
}
