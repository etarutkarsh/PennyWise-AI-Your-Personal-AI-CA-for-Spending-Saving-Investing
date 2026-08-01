package com.pennywise.financial.model;

import java.time.LocalDate;

/**
 * Expected return data for a given asset class, including disclaimer and freshness date.
 */
public record ExpectedReturn(
        AssetClass assetClass,
        double basePercent,
        double rangeMinPercent,
        double rangeMaxPercent,
        boolean isGovernmentRate,
        String rationale,
        String disclaimer,
        LocalDate lastUpdated
) {}
