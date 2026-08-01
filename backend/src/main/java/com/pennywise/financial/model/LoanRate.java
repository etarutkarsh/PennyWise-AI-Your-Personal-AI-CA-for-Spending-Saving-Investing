package com.pennywise.financial.model;

import java.time.LocalDate;

/**
 * Market benchmark interest rates for common Indian loan types.
 * Rates are 2025 averages from public lender data.
 */
public record LoanRate(
        String loanType,
        String displayName,
        double defaultRatePercent,
        double marketMinPercent,
        double marketMaxPercent,
        String source,
        LocalDate lastUpdated,
        String notes
) {}
