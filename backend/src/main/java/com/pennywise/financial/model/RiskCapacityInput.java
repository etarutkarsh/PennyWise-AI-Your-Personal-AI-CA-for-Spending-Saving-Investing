package com.pennywise.financial.model;

/**
 * Financial capacity inputs for objective risk capacity scoring.
 */
public record RiskCapacityInput(
        double monthlyIncome,
        double monthlyExpenses,
        double totalSavings,
        double totalDebt,
        int dependents,              // number of financial dependents
        boolean hasEmergencyFund,    // true if >= 3 months expenses saved
        boolean hasStableJob,        // true = salaried/stable, false = variable/self-employed
        int yearsToMajorGoal         // years until biggest financial goal
) {}
