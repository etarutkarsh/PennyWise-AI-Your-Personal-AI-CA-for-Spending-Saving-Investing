package com.pennywise.service;

import com.pennywise.dto.GoalCreateRequest;
import com.pennywise.dto.GoalDto;
import com.pennywise.entity.Goal;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
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

    public GoalService(GoalRepository goalRepository, CurrentUserProvider currentUserProvider) {
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
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

        return toDto(goalRepository.save(goal));
    }

    public List<GoalDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        return goalRepository.findByUserIdOrderByDeadlineAsc(user.getId())
                .stream().map(this::toDto).toList();
    }

    public GoalDto updateSavedAmount(UUID goalId, BigDecimal newSavedAmount) {
        Goal goal = goalRepository.findById(goalId)
                .orElseThrow(() -> new ResourceNotFoundException("Goal not found"));
        goal.setCurrentSaved(newSavedAmount);
        goal.setAchieved(newSavedAmount.compareTo(goal.getTargetAmount()) >= 0);
        applyRecommendation(goal);
        return toDto(goalRepository.save(goal));
    }

    /** Recomputes recommended monthly contribution + investment vehicle suggestion. */
    private void applyRecommendation(Goal goal) {
        long monthsRemaining = Math.max(1, Period.between(LocalDate.now(), goal.getDeadline()).toTotalMonths());
        BigDecimal shortfall = goal.getTargetAmount().subtract(goal.getCurrentSaved()).max(BigDecimal.ZERO);

        BigDecimal monthlyContribution = shortfall.divide(
                BigDecimal.valueOf(monthsRemaining), 0, RoundingMode.CEILING);
        goal.setRecommendedMonthlyContribution(monthlyContribution);

        // Simple horizon-based suggestion; the AI investment engine can refine this
        // using the user's risk appetite (see investment/ package).
        if (monthsRemaining <= 6) {
            goal.setInvestmentSuggestion("liquid_fund");
        } else if (monthsRemaining <= 18) {
            goal.setInvestmentSuggestion("rd");
        } else if (monthsRemaining <= 36) {
            goal.setInvestmentSuggestion("hybrid_fund");
        } else {
            goal.setInvestmentSuggestion("equity");
        }
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
