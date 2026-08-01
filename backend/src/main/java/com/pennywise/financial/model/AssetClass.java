package com.pennywise.financial.model;

/**
 * Asset classes with expected returns based on historical Indian market data.
 * Government-notified rates (PPF, EPF) are statutory; all others are market estimates.
 */
public enum AssetClass {

    LIQUID_FUND("Liquid Fund", 5.5, 4.0, 7.0, false, "RBI policy rate + 0.5%"),
    ARBITRAGE("Arbitrage Fund", 6.5, 5.0, 8.0, false, "Equity-debt spread"),
    DEBT_FUND("Debt Mutual Fund", 7.0, 5.0, 9.0, false, "Gilt + credit spread"),
    PPF("Public Provident Fund", 7.1, 7.1, 8.0, true, "GOI notified rate, reviewed quarterly"),
    EPF("Employee Provident Fund", 8.15, 8.0, 8.5, true, "EPFO declared rate"),
    GOLD("Gold (ETF/SGB)", 7.5, 5.0, 12.0, false, "Long-term CAGR, LBMA gold price"),
    EQUITY_INDEX("Equity Index Fund (Nifty50)", 11.5, 8.0, 15.0, false, "Nifty50 30-year CAGR ~12%"),
    INTERNATIONAL_EQUITY("International Equity", 10.5, 7.0, 14.0, false, "S&P500 + MSCI World blended"),
    DIRECT_EQUITY("Direct Equity", 13.0, 5.0, 20.0, false, "Skilled stock picking, high variance"),
    REAL_ESTATE("Real Estate (REITs)", 8.0, 5.0, 12.0, false, "Yield + appreciation");

    public final String displayName;
    public final double baseReturnPercent;    // Central estimate
    public final double rangeMinPercent;
    public final double rangeMaxPercent;
    public final boolean isGovernmentRate;    // If true, it's statutory not market
    public final String rationale;

    AssetClass(String displayName, double baseReturnPercent, double rangeMinPercent,
               double rangeMaxPercent, boolean isGovernmentRate, String rationale) {
        this.displayName = displayName;
        this.baseReturnPercent = baseReturnPercent;
        this.rangeMinPercent = rangeMinPercent;
        this.rangeMaxPercent = rangeMaxPercent;
        this.isGovernmentRate = isGovernmentRate;
        this.rationale = rationale;
    }
}
