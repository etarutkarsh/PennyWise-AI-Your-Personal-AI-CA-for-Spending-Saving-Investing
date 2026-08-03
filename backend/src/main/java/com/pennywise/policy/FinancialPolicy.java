package com.pennywise.policy;

import org.springframework.stereotype.Component;

/**
 * Centralised financial policy constants.
 * Rules (RBI regulations, tax slabs, health score weights) live here — not inside engine code.
 * Update this class when regulations change; engines stay untouched.
 */
@Component
public class FinancialPolicy {

    // ── Emergency Fund ────────────────────────────────────────────────────────
    public static final int MIN_EMERGENCY_FUND_MONTHS = 3;
    public static final int TARGET_EMERGENCY_FUND_MONTHS = 6;

    // ── Savings Rate ──────────────────────────────────────────────────────────
    public static final double MIN_SAVINGS_RATE = 0.15;
    public static final double TARGET_SAVINGS_RATE = 0.20;

    // ── Affordability / Debt ──────────────────────────────────────────────────
    public static final double SAFE_EMI_INCOME_RATIO = 0.40;
    public static final double MAX_DTI_RATIO = 0.50;
    public static final double WARN_DTI_RATIO = 0.40;

    // ── SIP Return Rates by Horizon (Step-Up SIP formula rates) ───────────────
    public static final double SIP_RATE_UNDER_12M = 0.07;    // RD / Liquid Fund
    public static final double SIP_RATE_12_TO_36M = 0.08;   // Debt / Hybrid
    public static final double SIP_RATE_36_TO_60M = 0.10;   // Balanced Fund
    public static final double SIP_RATE_OVER_60M  = 0.12;   // Equity SIP

    // ── Tax ───────────────────────────────────────────────────────────────────
    public static final double SECTION_80C_LIMIT = 150_000.0;
    public static final double SECTION_80CCD_ADDITIONAL = 50_000.0;

    // ── Cash Flow Safety (Thaler SMRT — never shock cash flow) ───────────────
    public static final double MAX_SIP_INCOME_RATIO = 0.10;
    public static final double DEFAULT_STEP_UP_RATE = 0.10;

    // ── Health Score Impact (points added per recommendation category) ────────
    public static final int HEALTH_POINTS_EMERGENCY_FUND   = 8;
    public static final int HEALTH_POINTS_SAVINGS_RATE     = 6;
    public static final int HEALTH_POINTS_GOAL_SIP         = 10;
    public static final int HEALTH_POINTS_TAX_OPTIMIZATION = 5;

    // ── Decision Confidence ───────────────────────────────────────────────────
    public static final double DEFAULT_CONFIDENCE_V1 = 0.75;

    // ── Fiduciary invariants — never override ─────────────────────────────────
    public static final String COMMISSION_POLICY = "ZERO_COMMISSION";
    public static final String FIDUCIARY_STATEMENT =
            "This recommendation is made in your interest alone. " +
            "PennyWise earns zero commission on any recommended product.";

    /** Returns the annualised SIP return rate appropriate for the given time horizon. */
    public double sipRateForHorizon(int months) {
        if (months < 12) return SIP_RATE_UNDER_12M;
        if (months < 36) return SIP_RATE_12_TO_36M;
        if (months < 60) return SIP_RATE_36_TO_60M;
        return SIP_RATE_OVER_60M;
    }
}
