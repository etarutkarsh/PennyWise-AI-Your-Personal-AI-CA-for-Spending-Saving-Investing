package com.pennywise.financial.engine;

import com.pennywise.financial.model.AssetClass;
import com.pennywise.financial.model.ExpectedReturn;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;

/**
 * Returns expected return data for all asset classes available to Indian retail investors.
 * Rates are calibrated to 2025 market conditions and SEBI-registered product categories.
 */
@Service
public class ExpectedReturnEngine {

    private static final String DISCLAIMER =
            "Expected returns are based on historical data and are not guaranteed. " +
            "Actual returns may vary significantly.";

    private static final LocalDate LAST_UPDATED = LocalDate.of(2025, 1, 1);

    /**
     * Returns all asset classes with their expected return profiles.
     */
    public List<ExpectedReturn> getAllReturns() {
        return Arrays.stream(AssetClass.values())
                .map(this::buildReturn)
                .toList();
    }

    /**
     * Returns the expected return for a specific asset class.
     */
    public ExpectedReturn getReturn(AssetClass assetClass) {
        return buildReturn(assetClass);
    }

    /**
     * Returns just the base expected return percentage for a specific asset class.
     */
    public double getBaseReturn(AssetClass assetClass) {
        return assetClass.baseReturnPercent;
    }

    private ExpectedReturn buildReturn(AssetClass assetClass) {
        return new ExpectedReturn(
                assetClass,
                assetClass.baseReturnPercent,
                assetClass.rangeMinPercent,
                assetClass.rangeMaxPercent,
                assetClass.isGovernmentRate,
                assetClass.rationale,
                DISCLAIMER,
                LAST_UPDATED
        );
    }
}
