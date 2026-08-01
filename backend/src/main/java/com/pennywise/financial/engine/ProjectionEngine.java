package com.pennywise.financial.engine;

import com.pennywise.financial.formula.Formula;
import org.springframework.stereotype.Service;

/**
 * Stateless financial projection engine.
 * All methods are annotated with {@link Formula} for the formula registry API.
 *
 * Reference: AMFI India; CFP Board TVM standards; RBI standard banking formula.
 */
@Service
public class ProjectionEngine {

    /**
     * Computes the future value of a Systematic Investment Plan (SIP).
     *
     * Formula: FV = PMT × [(1+r)^n - 1] / r
     * where r = monthly rate = annualReturnPercent / 12 / 100
     *
     * @param monthlyInvestment  amount invested each month (₹)
     * @param annualReturnPercent expected annual return (e.g. 12.0 for 12%)
     * @param months             investment duration in months
     * @return future value in ₹
     */
    @Formula(
            name = "SIP Future Value",
            purpose = "Calculate future value of a systematic investment plan",
            expression = "FV = PMT × [(1+r)^n - 1] / r",
            variables = {
                    "PMT = monthly investment",
                    "r = monthly return rate (annualRate / 12 / 100)",
                    "n = number of months"
            },
            reference = "Standard financial mathematics, AMFI India guidelines",
            assumptions = {
                    "Returns are constant throughout the period",
                    "Investments are made at the start of each month"
            },
            limitations = {
                    "Actual returns vary with market conditions",
                    "Does not account for inflation on the future value"
            }
    )
    public double sipFutureValue(double monthlyInvestment, double annualReturnPercent, int months) {
        if (months <= 0) return 0;
        if (annualReturnPercent == 0) return monthlyInvestment * months;

        double r = annualReturnPercent / 100.0 / 12.0;
        return monthlyInvestment * (Math.pow(1 + r, months) - 1) / r;
    }

    /**
     * Computes the monthly contribution needed to reach a financial goal.
     *
     * Formula: PMT = FV × r / [(1+r)^n - 1]
     * This is the inverse of SIP future value — solving for the periodic payment.
     *
     * @param futureValueNeeded  target amount minus current savings (shortfall)
     * @param annualReturnPercent assumed annual return on contributions
     * @param months             months remaining until deadline
     * @return required monthly contribution in ₹
     */
    @Formula(
            name = "Goal Monthly Contribution (PMT)",
            purpose = "Calculate monthly savings needed to reach a goal given a return assumption",
            expression = "PMT = FV × r / [(1+r)^n - 1]",
            variables = {
                    "FV = target amount minus current savings (shortfall)",
                    "r = monthly rate (annualRate / 12 / 100)",
                    "n = months remaining to deadline"
            },
            reference = "Time Value of Money (TVM), CFP Board standard",
            assumptions = {
                    "Consistent monthly contributions",
                    "Rate is achievable given investor's risk profile"
            },
            limitations = {
                    "Does not account for inflation on the goal target amount"
            }
    )
    public double goalMonthlyContribution(double futureValueNeeded, double annualReturnPercent, int months) {
        if (months <= 0) return futureValueNeeded;
        if (annualReturnPercent == 0) return futureValueNeeded / months;

        double r = annualReturnPercent / 100.0 / 12.0;
        return futureValueNeeded * r / (Math.pow(1 + r, months) - 1);
    }

    /**
     * Computes the Equated Monthly Installment (EMI) for a loan.
     *
     * Formula: EMI = P × r × (1+r)^n / [(1+r)^n - 1]
     *
     * @param principal         loan principal (₹)
     * @param annualRatePercent annual interest rate (e.g. 8.5 for 8.5%)
     * @param months            loan tenure in months
     * @return monthly EMI in ₹
     */
    @Formula(
            name = "EMI Calculation",
            purpose = "Calculate equated monthly installment for a loan",
            expression = "EMI = P × r × (1+r)^n / [(1+r)^n - 1]",
            variables = {
                    "P = principal loan amount",
                    "r = monthly interest rate (annualRate / 12 / 100)",
                    "n = loan tenure in months"
            },
            reference = "RBI standard banking formula, used by all Indian scheduled commercial banks",
            assumptions = {
                    "Fixed interest rate throughout the tenure",
                    "Equal monthly payments (reducing balance method)"
            },
            limitations = {
                    "Does not handle variable rate loans or floating rate periods",
                    "Prepayment and foreclosure charges not modelled"
            }
    )
    public double emi(double principal, double annualRatePercent, int months) {
        if (months <= 0) return principal;
        if (annualRatePercent == 0) return principal / months;

        double r = annualRatePercent / 100.0 / 12.0;
        double onePlusRtoN = Math.pow(1 + r, months);
        return principal * r * onePlusRtoN / (onePlusRtoN - 1);
    }

    /**
     * Computes compound growth of a lump-sum investment.
     *
     * Formula: FV = PV × (1 + r)^n
     * where n = years, r = annual rate / 100
     *
     * @param presentValue        initial investment (₹)
     * @param annualReturnPercent annual return rate
     * @param years               number of years
     * @return future value in ₹
     */
    @Formula(
            name = "Compound Growth (Lump Sum)",
            purpose = "Calculate future value of a one-time lump-sum investment",
            expression = "FV = PV × (1 + r)^n",
            variables = {
                    "PV = present value / initial investment",
                    "r = annual return rate / 100",
                    "n = number of years"
            },
            reference = "Compound interest formula, universally accepted",
            assumptions = { "Returns are compounded annually", "No withdrawals" },
            limitations = { "Inflation not adjusted unless using real return" }
    )
    public double compoundGrowth(double presentValue, double annualReturnPercent, int years) {
        return presentValue * Math.pow(1 + annualReturnPercent / 100.0, years);
    }

    /**
     * Computes the inflation-adjusted (real) return.
     *
     * Formula: Real Return = ((1 + nominal) / (1 + inflation)) - 1  [Fisher Equation]
     *
     * @param nominalReturnPercent  nominal return (e.g. 12.0 for 12%)
     * @param inflationRatePercent  inflation rate (e.g. 6.0 for 6%)
     * @return real return as a percentage
     */
    @Formula(
            name = "Inflation-Adjusted Real Return",
            purpose = "Compute the purchasing-power-adjusted return after inflation",
            expression = "Real Return = ((1 + nominal/100) / (1 + inflation/100)) - 1",
            variables = {
                    "nominal = nominal annual return percent",
                    "inflation = annual inflation rate percent"
            },
            reference = "Fisher Equation, Irving Fisher (1930)",
            assumptions = { "Inflation is constant over the period" },
            limitations = { "India CPI inflation is volatile; use 5-6% as a conservative assumption" }
    )
    public double inflationAdjustedReturn(double nominalReturnPercent, double inflationRatePercent) {
        double nominal = nominalReturnPercent / 100.0;
        double inflation = inflationRatePercent / 100.0;
        return ((1 + nominal) / (1 + inflation) - 1) * 100;
    }

    /**
     * Estimates the number of years for money to double using the Rule of 72.
     *
     * Formula: Years to Double ≈ 72 / annualReturnPercent
     *
     * @param annualReturnPercent annual return rate (e.g. 12.0 for 12%)
     * @return approximate years for the investment to double
     */
    @Formula(
            name = "Rule of 72",
            purpose = "Quick estimate of years needed to double an investment",
            expression = "Years to Double ≈ 72 / annualReturnPercent",
            variables = { "annualReturnPercent = annual return rate as a percentage" },
            reference = "Rule of 72, standard financial heuristic",
            assumptions = { "Constant compounding at the stated rate" },
            limitations = {
                    "Approximate only; accurate for rates between 6–10%",
                    "For exact calculation use compound growth formula"
            }
    )
    public double ruleOf72(double annualReturnPercent) {
        if (annualReturnPercent <= 0) return Double.MAX_VALUE;
        return 72.0 / annualReturnPercent;
    }

    /**
     * Computes the real return after accounting for inflation.
     * Convenience alias exposing both nominal and real rates together.
     *
     * @param nominalReturnPercent  nominal annual return
     * @param inflationRatePercent  expected inflation rate
     * @return real return percentage (can be negative if inflation > nominal)
     */
    @Formula(
            name = "Real Return (Simple)",
            purpose = "Simplified real return calculation for quick estimates",
            expression = "Real Return ≈ nominal - inflation",
            variables = {
                    "nominal = nominal annual return percent",
                    "inflation = inflation rate percent"
            },
            reference = "Simplified approximation of Fisher Equation",
            assumptions = { "Rates are small enough that cross-product term is negligible" },
            limitations = {
                    "Less accurate at high rates — use inflationAdjustedReturn() for precision"
            }
    )
    public double realReturn(double nominalReturnPercent, double inflationRatePercent) {
        return nominalReturnPercent - inflationRatePercent;
    }
}
