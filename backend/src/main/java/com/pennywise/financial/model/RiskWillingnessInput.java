package com.pennywise.financial.model;

/**
 * Psychographic inputs for risk willingness assessment.
 * All scores are on a 1–5 Likert scale.
 */
public record RiskWillingnessInput(
        int lossReaction,          // 1=sell everything, 5=buy more
        int timeHorizon,           // 1=<1yr, 2=1-3yr, 3=3-5yr, 4=5-10yr, 5=10yr+
        int investmentExperience,  // 1=none, 5=expert
        int volatilityComfort,     // 1=hate big swings, 5=fine with them
        int goalFlexibility        // 1=rigid target, 5=flexible
) {}
