package com.pennywise.engine.twin;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * A single data point in the net-worth projection series.
 */
@Getter
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ProjectionPoint {

    /** How many months from now this point represents. */
    private int monthsFromNow;

    /** Projected net worth at this point. */
    private BigDecimal netWorth;

    /** Cumulative savings contributed up to this point (excluding investment returns). */
    private BigDecimal cumulativeSavings;
}
