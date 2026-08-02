package com.pennywise.engine.behavioral;

import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;

/**
 * Generates human-readable insights, trait grades, and behavior classifications
 * from a computed {@link BehaviorScores} value object.
 */
@Slf4j
@Component
public class BehaviorInsightEngine {

    public List<String> generateInsights(BehaviorScores scores) {
        List<String> insights = new ArrayList<>();

        // Follow rate insight
        if (scores.getDecisionsAnalyzed() > 0) {
            insights.add(String.format(
                    "You followed %d%% of recommendations in the last analysis period.",
                    scores.getRecommendationFollowRate()));
        }

        // Salary euphoria
        if (scores.getPatterns().contains(BehaviorPattern.SALARY_EUPHORIA)) {
            insights.add("Spending spiked within 48–72 hours of salary credit on multiple occasions. " +
                    "Consider a 72-hour cooling rule before large purchases post-salary.");
        }

        // Consistent saver
        if (scores.getPatterns().contains(BehaviorPattern.CONSISTENT_SAVER)) {
            insights.add(String.format(
                    "Your savings rate has been consistent across %d months of data. " +
                            "You are on track with your financial goals.",
                    scores.getMonthsOfData()));
        }

        // Goal drift
        if (scores.getPatterns().contains(BehaviorPattern.GOAL_DRIFT)) {
            insights.add("Budget limits were exceeded multiple times with no completed goals. " +
                    "Consider breaking down goals into smaller monthly milestones.");
        }

        // Disciplined follower
        if (scores.getPatterns().contains(BehaviorPattern.DISCIPLINED_FOLLOWER)) {
            insights.add("You consistently follow financial recommendations. " +
                    "This behavioral pattern is strongly correlated with long-term wealth building.");
        }

        // Recommendation resistant
        if (scores.getPatterns().contains(BehaviorPattern.RECOMMENDATION_RESISTANT)) {
            insights.add("You tend to deviate from recommendations. " +
                    "Reviewing past decisions and their outcomes can help calibrate future choices.");
        }

        // Emergency resilient
        if (scores.getPatterns().contains(BehaviorPattern.EMERGENCY_RESILIENT)) {
            insights.add("You have reached multiple emergency fund milestones. " +
                    "This makes you financially resilient against unexpected expenses.");
        }

        // Impulse purchaser
        if (scores.getPatterns().contains(BehaviorPattern.IMPULSE_PURCHASER)) {
            insights.add("A pattern of impulsive large purchases has been detected. " +
                    "Automating savings before spending can significantly reduce impulse buying.");
        }

        // Discipline trend insight
        if (scores.getDisciplineScore() >= 80) {
            insights.add("Financial discipline is your strongest behavioral trait this period.");
        } else if (scores.getDisciplineScore() < 40) {
            insights.add("Financial discipline has room for improvement. " +
                    "Small consistent actions compound into major behavioral change.");
        }

        // Goal commitment highlight
        int highest = Math.max(scores.getDisciplineScore(),
                Math.max(scores.getGoalCommitmentScore(), scores.getSavingsDisciplineScore()));
        if (highest == scores.getGoalCommitmentScore() && scores.getGoalCommitmentScore() >= 70) {
            insights.add("Goal commitment is the strongest behavioral trait this period.");
        }

        // Low data warning
        if (scores.getEventsAnalyzed() < 5) {
            insights.add("Profile confidence is low. More financial activity will improve insight accuracy.");
        }

        // Ensure at least 2 insights even with no data
        if (insights.isEmpty()) {
            insights.add("Your behavioral profile is being built. Keep tracking your finances for personalized insights.");
            insights.add("The more decisions and transactions you record, the more accurate your profile becomes.");
        } else if (insights.size() == 1) {
            insights.add("Continue tracking your spending and goal progress to unlock deeper behavioral insights.");
        }

        return insights;
    }

    public Map<String, String> computeTraits(BehaviorScores scores) {
        Map<String, String> traits = new LinkedHashMap<>();
        traits.put("discipline", scoreToGrade(scores.getDisciplineScore()));
        traits.put("impulseControl", scoreToGrade(scores.getImpulseScore()));
        traits.put("goalCommitment", scoreToGrade(scores.getGoalCommitmentScore()));
        traits.put("savingsConsistency", scoreToGrade(scores.getSavingsDisciplineScore()));
        traits.put("riskManagement", scoreToGrade(scores.getRiskBehaviorScore()));
        traits.put("spendingStability", scoreToGrade(scores.getSpendingStabilityScore()));
        return traits;
    }

    public String classifyPrimaryBehavior(BehaviorScores scores) {
        Set<BehaviorPattern> patterns = scores.getPatterns();

        if (patterns.isEmpty() && scores.getEventsAnalyzed() < 5) {
            return "Building Profile";
        }

        // Priority order for primary classification
        if (patterns.contains(BehaviorPattern.CONSISTENT_SAVER) &&
                patterns.contains(BehaviorPattern.DISCIPLINED_FOLLOWER)) {
            return "Disciplined Saver";
        }
        if (patterns.contains(BehaviorPattern.CONSISTENT_SAVER)) {
            return "Consistent Saver";
        }
        if (patterns.contains(BehaviorPattern.DISCIPLINED_FOLLOWER)) {
            return "Disciplined Follower";
        }
        if (patterns.contains(BehaviorPattern.IMPULSE_PURCHASER)) {
            return "Impulse Purchaser";
        }
        if (patterns.contains(BehaviorPattern.GOAL_DRIFT)) {
            return "Goal Drifter";
        }
        if (patterns.contains(BehaviorPattern.EMERGENCY_RESILIENT)) {
            return "Emergency Resilient";
        }
        if (patterns.contains(BehaviorPattern.RISK_AVERSE)) {
            return "Risk Averse Saver";
        }
        if (patterns.contains(BehaviorPattern.RECOMMENDATION_RESISTANT)) {
            return "Independent Thinker";
        }

        // Score-based fallback classification
        int maxScore = Math.max(scores.getDisciplineScore(),
                Math.max(scores.getGoalCommitmentScore(), scores.getSavingsDisciplineScore()));

        if (maxScore == scores.getDisciplineScore() && maxScore >= 65) {
            return "Disciplined Planner";
        }
        if (maxScore == scores.getGoalCommitmentScore() && maxScore >= 65) {
            return "Goal Achiever";
        }
        if (maxScore == scores.getSavingsDisciplineScore() && maxScore >= 65) {
            return "Steady Saver";
        }

        return "Balanced Spender";
    }

    public String classifySecondaryBehavior(BehaviorScores scores) {
        Set<BehaviorPattern> patterns = scores.getPatterns();

        if (patterns.contains(BehaviorPattern.SALARY_EUPHORIA)) {
            return "Salary Euphoria";
        }
        if (patterns.contains(BehaviorPattern.RISK_AVERSE) &&
                !patterns.contains(BehaviorPattern.CONSISTENT_SAVER)) {
            return "Risk Averse";
        }
        if (patterns.contains(BehaviorPattern.EMERGENCY_RESILIENT)) {
            return "Emergency Prepared";
        }
        if (scores.getImpulseScore() < 40) {
            return "Impulse Prone";
        }
        if (scores.getConsistencyScore() >= 75) {
            return "Highly Consistent";
        }
        if (scores.getRiskBehaviorScore() >= 75) {
            return "Risk Confident";
        }

        return null; // No clear secondary behavior
    }

    /**
     * Converts a 0-100 score to a letter grade.
     * Package-visible for testing.
     */
    String scoreToGrade(int score) {
        if (score >= 90) return "A";
        if (score >= 85) return "A-";
        if (score >= 80) return "B+";
        if (score >= 75) return "B";
        if (score >= 70) return "B-";
        if (score >= 60) return "C";
        if (score >= 50) return "C-";
        return "D";
    }
}
