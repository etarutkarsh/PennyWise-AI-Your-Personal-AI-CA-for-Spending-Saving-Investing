package com.pennywise.engine.decision;

import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.dto.ScenarioDto;
import com.pennywise.dto.TradeoffDto;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

/**
 * Decision Engine v2 — the canonical financial decision orchestrator.
 * Handles affordability evaluation plus explainability, tradeoffs, and
 * recommendation strength scoring. Replaces the rule logic previously
 * in {@code AffordabilityEngine}, which now delegates here.
 */
@Component
public class DecisionEngine {

    private static final BigDecimal EMERGENCY_FUND_MONTHS = BigDecimal.valueOf(6);
    private static final BigDecimal SAFE_EMI_INCOME_RATIO = new BigDecimal("0.40");
    private static final BigDecimal SAVE_RATE_OF_SURPLUS = new BigDecimal("0.50");
    private static final int CALC_SCALE = 10;

    private final RiskEngine riskEngine;
    private final TradeoffEngine tradeoffEngine;
    private final ExplainabilityEngine explainEngine;

    public DecisionEngine(@Qualifier("decisionRiskEngine") RiskEngine riskEngine,
                          TradeoffEngine tradeoffEngine,
                          ExplainabilityEngine explainEngine) {
        this.riskEngine = riskEngine;
        this.tradeoffEngine = tradeoffEngine;
        this.explainEngine = explainEngine;
    }

    // TODO (Sprint 3): inject BehaviorProfileRepository here and load the user's BehaviorProfile
    // before determining verdict. If impulseScore < 40, apply a stronger bias toward WAIT_AND_SAVE.
    // If disciplineScore >= 80, trust the user more with SAFE_TO_BUY thresholds.
    // This personalizes recommendations based on the user's historical behavioral patterns.
    public AffordabilityResponse evaluate(DecisionContext ctx) {

        BigDecimal price = ctx.getPrice();
        BigDecimal downPayment = DecisionContext.orZero(ctx.getDownPayment());
        BigDecimal existingEmi = DecisionContext.orZero(ctx.getExistingMonthlyEmi());
        boolean isLoan = ctx.isLoan();

        BigDecimal loanAmount = ctx.loanAmount();
        BigDecimal newEmi = isLoan
                ? calcEmi(loanAmount, ctx.getInterestRatePercent(), ctx.getTenureMonths())
                : BigDecimal.ZERO;

        BigDecimal monthlyIncome = DecisionContext.orZero(ctx.getMonthlyIncome());
        BigDecimal avgMonthlyExpenses = DecisionContext.orZero(ctx.getAvgMonthlyExpenses());
        BigDecimal currentEmergencyFund = DecisionContext.orZero(ctx.getCurrentEmergencyFund());

        BigDecimal grossSurplus = monthlyIncome.subtract(avgMonthlyExpenses).max(BigDecimal.ZERO);
        BigDecimal totalMonthlyDebt = existingEmi.add(newEmi);
        BigDecimal surplusAfterEmi = grossSurplus.subtract(newEmi).max(BigDecimal.ZERO);

        BigDecimal dtiRatio = monthlyIncome.compareTo(BigDecimal.ZERO) > 0
                ? totalMonthlyDebt.divide(monthlyIncome, CALC_SCALE, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100)).setScale(1, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        BigDecimal recommendedEF = avgMonthlyExpenses.multiply(EMERGENCY_FUND_MONTHS);
        BigDecimal cashOutToday = isLoan ? downPayment : price;
        BigDecimal efAfterPurchase = currentEmergencyFund.subtract(cashOutToday);

        // ── Verdict ──────────────────────────────────────────────────────────
        List<String> reasons = new ArrayList<>();
        List<String> warnings = new ArrayList<>();
        List<String> recommendations = new ArrayList<>();

        String verdict = determineVerdict(grossSurplus, dtiRatio, efAfterPurchase,
                recommendedEF, isLoan, newEmi, reasons);

        enrichWarnings(warnings, dtiRatio, efAfterPurchase, avgMonthlyExpenses,
                surplusAfterEmi, monthlyIncome, isLoan);
        buildRecommendations(recommendations, verdict, dtiRatio, efAfterPurchase,
                recommendedEF, grossSurplus, isLoan, newEmi, monthlyIncome,
                avgMonthlyExpenses, currentEmergencyFund);

        // ── Confidence ───────────────────────────────────────────────────────
        int confidence = computeConfidence(verdict, dtiRatio, efAfterPurchase,
                avgMonthlyExpenses, surplusAfterEmi, monthlyIncome);

        // ── Max affordable ───────────────────────────────────────────────────
        BigDecimal maxEmi = monthlyIncome.multiply(SAFE_EMI_INCOME_RATIO)
                .subtract(existingEmi).max(BigDecimal.ZERO);
        BigDecimal maxAffordablePrice;
        if (isLoan && ctx.getTenureMonths() != null) {
            BigDecimal maxLoan = reverseEmi(maxEmi, ctx.getInterestRatePercent(), ctx.getTenureMonths());
            maxAffordablePrice = maxLoan.add(downPayment);
        } else {
            BigDecimal buffer = currentEmergencyFund.subtract(recommendedEF).max(BigDecimal.ZERO);
            maxAffordablePrice = buffer.add(grossSurplus.multiply(SAVE_RATE_OF_SURPLUS).multiply(BigDecimal.valueOf(3)));
        }
        maxAffordablePrice = maxAffordablePrice.setScale(0, RoundingMode.FLOOR);

        // ── Wait / save logic ─────────────────────────────────────────────────
        Integer waitMonths = null;
        BigDecimal monthlySavings = null;
        LocalDate expectedDate = null;
        String investmentSuggestion = null;
        BigDecimal efImpact = cashOutToday;

        if ("WAIT_AND_SAVE".equals(verdict) || "DONT_BUY".equals(verdict)) {
            BigDecimal savingRate = grossSurplus.multiply(SAVE_RATE_OF_SURPLUS)
                    .max(BigDecimal.ONE).setScale(0, RoundingMode.CEILING);
            BigDecimal bufferAboveFloor = currentEmergencyFund.subtract(recommendedEF).max(BigDecimal.ZERO);
            BigDecimal shortfall = cashOutToday.subtract(bufferAboveFloor).max(BigDecimal.ZERO);
            int months = shortfall.divide(savingRate, 0, RoundingMode.CEILING).intValue();
            waitMonths = Math.max(1, months);
            monthlySavings = savingRate;
            expectedDate = LocalDate.now().plusMonths(waitMonths);
            investmentSuggestion = waitMonths <= 6 ? "liquid_fund" : "debt_plus_equity";
        }

        // ── Scenarios ────────────────────────────────────────────────────────
        List<ScenarioDto> scenarios = buildScenarios(ctx, monthlyIncome, avgMonthlyExpenses,
                currentEmergencyFund, grossSurplus, existingEmi, isLoan, loanAmount, newEmi,
                efAfterPurchase, surplusAfterEmi, dtiRatio);

        // ── Top-level recommendation strength ────────────────────────────────
        String recommendationStrength = RecommendationStrength.from(confidence).name();
        List<String> strengthEvidence = explainEngine.strengthEvidence(
                confidence, dtiRatio, efAfterPurchase.max(BigDecimal.ZERO),
                avgMonthlyExpenses, surplusAfterEmi, monthlyIncome);

        return AffordabilityResponse.builder()
                .verdict(verdict)
                .reason(reasons.isEmpty() ? "" : reasons.get(0))
                .recommendedWaitMonths(waitMonths)
                .recommendedMonthlySavings(monthlySavings)
                .expectedPurchaseDate(expectedDate)
                .emergencyFundImpact(efImpact)
                .projectedEmergencyFundAfterPurchase(efAfterPurchase.max(BigDecimal.ZERO))
                .investmentSuggestion(investmentSuggestion)
                .confidence(confidence)
                .monthlyEmi(isLoan ? newEmi.setScale(0, RoundingMode.CEILING) : null)
                .dtiRatio(dtiRatio)
                .remainingMonthlySurplus(surplusAfterEmi.setScale(0, RoundingMode.FLOOR))
                .maxAffordablePrice(maxAffordablePrice)
                .reasons(reasons)
                .warnings(warnings)
                .recommendations(recommendations)
                .scenarios(scenarios)
                .recommendationStrength(recommendationStrength)
                .strengthEvidence(strengthEvidence)
                .build();
    }

    // ── Verdict logic ─────────────────────────────────────────────────────────

    private String determineVerdict(BigDecimal grossSurplus, BigDecimal dtiRatio,
                                     BigDecimal efAfterPurchase, BigDecimal recommendedEF,
                                     boolean isLoan, BigDecimal newEmi, List<String> reasons) {
        if (grossSurplus.compareTo(BigDecimal.ZERO) <= 0) {
            reasons.add("Your monthly expenses meet or exceed your income — no surplus to fund this purchase.");
            return "DONT_BUY";
        }
        if (isLoan && newEmi.compareTo(grossSurplus) >= 0) {
            reasons.add("The monthly EMI of ₹" + newEmi.setScale(0, RoundingMode.HALF_UP)
                    + " would consume your entire monthly surplus.");
            return "DONT_BUY";
        }
        if (dtiRatio.compareTo(BigDecimal.valueOf(50)) > 0) {
            reasons.add("Total debt obligations would reach " + dtiRatio
                    + "% of income — above the 50% danger threshold.");
            return "DONT_BUY";
        }
        if (efAfterPurchase.compareTo(recommendedEF) < 0) {
            reasons.add("This purchase would drop your emergency fund below the recommended 6-month safety floor.");
            return "WAIT_AND_SAVE";
        }
        if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) {
            reasons.add("Your debt-to-income ratio of " + dtiRatio
                    + "% is in the caution zone — recommended maximum is 40%.");
            return "WAIT_AND_SAVE";
        }
        reasons.add("Your emergency fund stays intact and monthly debt obligations remain within healthy limits.");
        return "SAFE_TO_BUY";
    }

    // ── Warnings ──────────────────────────────────────────────────────────────

    private void enrichWarnings(List<String> warnings, BigDecimal dtiRatio,
                                 BigDecimal efAfterPurchase, BigDecimal avgMonthlyExpenses,
                                 BigDecimal surplusAfterEmi, BigDecimal income, boolean isLoan) {
        if (isLoan && dtiRatio.compareTo(BigDecimal.valueOf(36)) > 0
                && dtiRatio.compareTo(BigDecimal.valueOf(50)) <= 0) {
            warnings.add("DTI of " + dtiRatio + "% is above the recommended 36% — keep other borrowing minimal.");
        }
        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 1, RoundingMode.HALF_UP);
            if (efMonths.compareTo(BigDecimal.valueOf(3)) < 0 && efAfterPurchase.compareTo(BigDecimal.ZERO) > 0) {
                warnings.add("Post-purchase emergency fund covers only " + efMonths
                        + " months — aim for at least 6 months.");
            }
        }
        if (income.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal surplusRatio = surplusAfterEmi.divide(income, 4, RoundingMode.HALF_UP);
            if (surplusRatio.compareTo(new BigDecimal("0.10")) < 0) {
                warnings.add("After this EMI, less than 10% of income remains as free surplus — leaves little room for emergencies.");
            }
        }
    }

    // ── Recommendations ───────────────────────────────────────────────────────

    private void buildRecommendations(List<String> recs, String verdict, BigDecimal dtiRatio,
                                       BigDecimal efAfterPurchase, BigDecimal recommendedEF,
                                       BigDecimal surplus, boolean isLoan, BigDecimal newEmi,
                                       BigDecimal income, BigDecimal expenses,
                                       BigDecimal currentEF) {
        switch (verdict) {
            case "SAFE_TO_BUY" -> {
                recs.add("You're in a good position. Proceed — and log this purchase to keep your budget on track.");
                if (isLoan) {
                    recs.add("Set up a standing instruction for the EMI so you never miss a payment.");
                }
            }
            case "WAIT_AND_SAVE" -> {
                BigDecimal savingRate = surplus.multiply(SAVE_RATE_OF_SURPLUS).setScale(0, RoundingMode.CEILING);
                recs.add("Auto-transfer ₹" + savingRate + "/month to a liquid fund. You'll hit your target sooner than you think.");
                if (efAfterPurchase.compareTo(recommendedEF) < 0) {
                    BigDecimal gap = recommendedEF.subtract(currentEF).max(BigDecimal.ZERO);
                    recs.add("Build your emergency fund by ₹" + gap.setScale(0, RoundingMode.CEILING) + " before making this purchase.");
                }
                if (isLoan && dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) {
                    recs.add("Consider increasing your down payment to bring the EMI down and reduce your DTI ratio.");
                }
            }
            case "DONT_BUY" -> {
                recs.add("Focus on closing existing debt or growing income before taking on this expense.");
                recs.add("Revisit in 3–6 months once your monthly surplus improves.");
            }
        }
    }

    // ── Confidence ────────────────────────────────────────────────────────────

    private int computeConfidence(String verdict, BigDecimal dtiRatio, BigDecimal efAfterPurchase,
                                   BigDecimal avgMonthlyExpenses, BigDecimal surplusAfterEmi,
                                   BigDecimal income) {
        int base = switch (verdict) {
            case "SAFE_TO_BUY" -> 85;
            case "WAIT_AND_SAVE" -> 55;
            default -> 25;
        };

        // DTI adjustments
        if (dtiRatio.compareTo(BigDecimal.valueOf(50)) > 0) base -= 25;
        else if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) base -= 15;
        else if (dtiRatio.compareTo(BigDecimal.valueOf(36)) > 0) base -= 5;

        // Emergency fund buffer
        if (avgMonthlyExpenses.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal efMonths = efAfterPurchase.divide(avgMonthlyExpenses, 2, RoundingMode.HALF_UP);
            if (efMonths.compareTo(BigDecimal.valueOf(3)) < 0) base -= 15;
            else if (efMonths.compareTo(BigDecimal.valueOf(6)) < 0) base -= 8;
            else base += 3;
        }

        // Surplus comfort after EMI
        if (income.compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal surplusRatio = surplusAfterEmi.divide(income, 4, RoundingMode.HALF_UP);
            if (surplusRatio.compareTo(new BigDecimal("0.20")) < 0) base -= 10;
            else if (surplusRatio.compareTo(new BigDecimal("0.40")) >= 0) base += 5;
        }

        return Math.max(10, Math.min(95, base));
    }

    // ── Scenario builder ──────────────────────────────────────────────────────

    private List<ScenarioDto> buildScenarios(DecisionContext ctx,
                                              BigDecimal income, BigDecimal expenses, BigDecimal ef,
                                              BigDecimal surplus, BigDecimal existingEmi,
                                              boolean isLoan, BigDecimal loanAmount, BigDecimal currentEmi,
                                              BigDecimal topLevelEfAfterPurchase,
                                              BigDecimal topLevelSurplusAfterEmi,
                                              BigDecimal topLevelDti) {
        List<ScenarioDto> list = new ArrayList<>();

        BigDecimal price = ctx.getPrice();
        BigDecimal downPayment = DecisionContext.orZero(ctx.getDownPayment());
        BigDecimal rate = ctx.getInterestRatePercent();
        int tenure = ctx.getTenureMonths() != null ? ctx.getTenureMonths() : 0;
        BigDecimal recommendedEF = expenses.multiply(EMERGENCY_FUND_MONTHS);

        // Baseline EMI and interest (for Buy Today — used for delta comparisons in tradeoffs)
        BigDecimal baselineEmi = isLoan ? currentEmi : BigDecimal.ZERO;
        BigDecimal baselineInterest = isLoan && tenure > 0
                ? currentEmi.multiply(BigDecimal.valueOf(tenure)).subtract(loanAmount).max(BigDecimal.ZERO)
                : BigDecimal.ZERO;

        // Scenario 1: Buy Today
        {
            BigDecimal cashOut = isLoan ? downPayment : price;
            BigDecimal emi = currentEmi;
            BigDecimal dti = calcDti(existingEmi.add(emi), income);
            BigDecimal efAfter = ef.subtract(cashOut);
            BigDecimal surplusAfter = surplus.subtract(emi).max(BigDecimal.ZERO);
            String v = quickVerdict(surplus, dti, efAfter, recommendedEF, isLoan, emi);
            int conf = computeConfidence(v, dti, efAfter, expenses, surplusAfter, income);
            BigDecimal totalInterest = isLoan
                    ? emi.multiply(BigDecimal.valueOf(tenure)).subtract(loanAmount).max(BigDecimal.ZERO)
                    : BigDecimal.ZERO;

            List<TradeoffDto> tradeoffs = tradeoffEngine.forScenario(
                    "Buy Today", emi, baselineEmi, totalInterest, baselineInterest,
                    efAfter, expenses, surplusAfter, income, false);
            List<String> whyThis = explainEngine.whyThis(v, BigDecimal.valueOf(conf), dti,
                    efAfter, expenses, surplusAfter, income, "Buy Today");

            list.add(ScenarioDto.builder()
                    .label("Buy Today")
                    .verdict(v)
                    .confidence(conf)
                    .recommendationStrength(RecommendationStrength.from(conf).name())
                    .monthlyEmi(isLoan ? emi.setScale(0, RoundingMode.CEILING) : null)
                    .totalInterest(isLoan ? totalInterest.setScale(0, RoundingMode.HALF_UP) : null)
                    .totalCost((isLoan ? price.add(totalInterest) : price).setScale(0, RoundingMode.HALF_UP))
                    .summary(isLoan
                            ? "EMI ₹" + emi.setScale(0, RoundingMode.CEILING) + "/mo · Total cost ₹" + price.add(totalInterest).setScale(0, RoundingMode.HALF_UP)
                            : "One-time payment of ₹" + price.setScale(0, RoundingMode.HALF_UP))
                    .isRecommended(false)
                    .whyThis(whyThis)
                    .whyNot(new ArrayList<>())  // filled in after marking recommended
                    .tradeoffs(tradeoffs)
                    .build());
        }

        if (isLoan && tenure > 0) {
            // Scenario 2: Wait 6 months — save 50% of surplus each month
            {
                BigDecimal extra = surplus.multiply(SAVE_RATE_OF_SURPLUS).multiply(BigDecimal.valueOf(6));
                BigDecimal newDown = downPayment.add(extra);
                BigDecimal newLoan = price.subtract(newDown).max(BigDecimal.ZERO);
                BigDecimal emi2 = calcEmi(newLoan, rate, tenure);
                BigDecimal dti2 = calcDti(existingEmi.add(emi2), income);
                BigDecimal newEf = ef.add(surplus.multiply(SAVE_RATE_OF_SURPLUS).multiply(BigDecimal.valueOf(6)));
                BigDecimal efAfter2 = newEf.subtract(newDown);
                BigDecimal surplusAfter2 = surplus.subtract(emi2).max(BigDecimal.ZERO);
                String v2 = quickVerdict(surplus, dti2, efAfter2, recommendedEF, true, emi2);
                int conf2 = computeConfidence(v2, dti2, efAfter2, expenses, surplusAfter2, income);
                BigDecimal totalInterest2 = emi2.multiply(BigDecimal.valueOf(tenure)).subtract(newLoan).max(BigDecimal.ZERO);
                BigDecimal emiReduction = currentEmi.subtract(emi2).max(BigDecimal.ZERO);

                List<TradeoffDto> tradeoffs2 = tradeoffEngine.forScenario(
                        "Wait 6 Months", emi2, baselineEmi, totalInterest2, baselineInterest,
                        efAfter2, expenses, surplusAfter2, income, false);
                List<String> whyThis2 = explainEngine.whyThis(v2, BigDecimal.valueOf(conf2), dti2,
                        efAfter2, expenses, surplusAfter2, income, "Wait 6 Months");

                list.add(ScenarioDto.builder()
                        .label("Wait 6 Months")
                        .verdict(v2)
                        .confidence(conf2)
                        .recommendationStrength(RecommendationStrength.from(conf2).name())
                        .monthlyEmi(emi2.setScale(0, RoundingMode.CEILING))
                        .totalInterest(totalInterest2.setScale(0, RoundingMode.HALF_UP))
                        .totalCost(price.add(totalInterest2).setScale(0, RoundingMode.HALF_UP))
                        .summary("Save ₹" + extra.setScale(0, RoundingMode.HALF_UP) + " extra · EMI drops ₹" + emiReduction.setScale(0, RoundingMode.HALF_UP) + "/mo")
                        .isRecommended(false)
                        .whyThis(whyThis2)
                        .whyNot(new ArrayList<>())
                        .tradeoffs(tradeoffs2)
                        .build());
            }

            // Scenario 3: Increase down payment by 20% of loan
            {
                BigDecimal extraDown = loanAmount.multiply(new BigDecimal("0.20")).setScale(0, RoundingMode.CEILING);
                BigDecimal newDown3 = downPayment.add(extraDown);
                BigDecimal newLoan3 = price.subtract(newDown3).max(BigDecimal.ZERO);
                BigDecimal emi3 = calcEmi(newLoan3, rate, tenure);
                BigDecimal dti3 = calcDti(existingEmi.add(emi3), income);
                BigDecimal efAfter3 = ef.subtract(newDown3);
                BigDecimal surplusAfter3 = surplus.subtract(emi3).max(BigDecimal.ZERO);
                String v3 = quickVerdict(surplus, dti3, efAfter3, recommendedEF, true, emi3);
                int conf3 = computeConfidence(v3, dti3, efAfter3, expenses, surplusAfter3, income);
                BigDecimal totalInterest3 = emi3.multiply(BigDecimal.valueOf(tenure)).subtract(newLoan3).max(BigDecimal.ZERO);
                BigDecimal emiSaving = currentEmi.subtract(emi3).max(BigDecimal.ZERO);

                List<TradeoffDto> tradeoffs3 = tradeoffEngine.forScenario(
                        "Increase Down Payment", emi3, baselineEmi, totalInterest3, baselineInterest,
                        efAfter3, expenses, surplusAfter3, income, false);
                List<String> whyThis3 = explainEngine.whyThis(v3, BigDecimal.valueOf(conf3), dti3,
                        efAfter3, expenses, surplusAfter3, income, "Increase Down Payment");

                list.add(ScenarioDto.builder()
                        .label("Increase Down Payment")
                        .verdict(v3)
                        .confidence(conf3)
                        .recommendationStrength(RecommendationStrength.from(conf3).name())
                        .monthlyEmi(emi3.setScale(0, RoundingMode.CEILING))
                        .totalInterest(totalInterest3.setScale(0, RoundingMode.HALF_UP))
                        .totalCost(price.add(totalInterest3).setScale(0, RoundingMode.HALF_UP))
                        .summary("Add ₹" + extraDown + " upfront · EMI saves ₹" + emiSaving.setScale(0, RoundingMode.HALF_UP) + "/mo")
                        .isRecommended(false)
                        .whyThis(whyThis3)
                        .whyNot(new ArrayList<>())
                        .tradeoffs(tradeoffs3)
                        .build());
            }

            // Scenario 4: Extend tenure by 24 months
            {
                int extTenure = tenure + 24;
                BigDecimal emi4 = calcEmi(loanAmount, rate, extTenure);
                BigDecimal dti4 = calcDti(existingEmi.add(emi4), income);
                BigDecimal efAfter4 = ef.subtract(downPayment);
                BigDecimal surplusAfter4 = surplus.subtract(emi4).max(BigDecimal.ZERO);
                String v4 = quickVerdict(surplus, dti4, efAfter4, recommendedEF, true, emi4);
                int conf4 = computeConfidence(v4, dti4, efAfter4, expenses, surplusAfter4, income);
                BigDecimal totalInterest4 = emi4.multiply(BigDecimal.valueOf(extTenure)).subtract(loanAmount).max(BigDecimal.ZERO);
                BigDecimal extraInterest = totalInterest4.subtract(
                        currentEmi.multiply(BigDecimal.valueOf(tenure)).subtract(loanAmount).max(BigDecimal.ZERO)).max(BigDecimal.ZERO);
                BigDecimal emiReduction4 = currentEmi.subtract(emi4).max(BigDecimal.ZERO);
                String extLabel = "Extend to " + (extTenure / 12) + "-Yr Loan";

                List<TradeoffDto> tradeoffs4 = tradeoffEngine.forScenario(
                        extLabel, emi4, baselineEmi, totalInterest4, baselineInterest,
                        efAfter4, expenses, surplusAfter4, income, false);
                List<String> whyThis4 = explainEngine.whyThis(v4, BigDecimal.valueOf(conf4), dti4,
                        efAfter4, expenses, surplusAfter4, income, extLabel);

                list.add(ScenarioDto.builder()
                        .label(extLabel)
                        .verdict(v4)
                        .confidence(conf4)
                        .recommendationStrength(RecommendationStrength.from(conf4).name())
                        .monthlyEmi(emi4.setScale(0, RoundingMode.CEILING))
                        .totalInterest(totalInterest4.setScale(0, RoundingMode.HALF_UP))
                        .totalCost(price.add(totalInterest4).setScale(0, RoundingMode.HALF_UP))
                        .summary("EMI ↓₹" + emiReduction4.setScale(0, RoundingMode.HALF_UP) + "/mo · ₹" + extraInterest.setScale(0, RoundingMode.HALF_UP) + " extra interest")
                        .isRecommended(false)
                        .whyThis(whyThis4)
                        .whyNot(new ArrayList<>())
                        .tradeoffs(tradeoffs4)
                        .build());
            }
        } else {
            // Lump-sum wait scenarios
            BigDecimal saveMonthly = surplus.multiply(SAVE_RATE_OF_SURPLUS);

            // Wait 3 months
            {
                BigDecimal extra3 = saveMonthly.multiply(BigDecimal.valueOf(3));
                BigDecimal newEf3 = ef.add(extra3);
                BigDecimal efAfter3 = newEf3.subtract(price);
                String v3 = quickVerdict(surplus, BigDecimal.ZERO, efAfter3, recommendedEF, false, BigDecimal.ZERO);
                int conf3 = computeConfidence(v3, BigDecimal.ZERO, efAfter3, expenses, surplus, income);

                List<TradeoffDto> tradeoffs3 = tradeoffEngine.forScenario(
                        "Wait 3 Months", null, null, null, null,
                        efAfter3, expenses, surplus, income, false);
                List<String> whyThis3 = explainEngine.whyThis(v3, BigDecimal.valueOf(conf3), BigDecimal.ZERO,
                        efAfter3, expenses, surplus, income, "Wait 3 Months");

                list.add(ScenarioDto.builder()
                        .label("Wait 3 Months")
                        .verdict(v3)
                        .confidence(conf3)
                        .recommendationStrength(RecommendationStrength.from(conf3).name())
                        .monthlyEmi(null)
                        .totalInterest(null)
                        .totalCost(price)
                        .summary("Save ₹" + extra3.setScale(0, RoundingMode.HALF_UP) + " over 3 months to buffer your emergency fund")
                        .isRecommended(false)
                        .whyThis(whyThis3)
                        .whyNot(new ArrayList<>())
                        .tradeoffs(tradeoffs3)
                        .build());
            }

            // Wait 6 months
            {
                BigDecimal extra6 = saveMonthly.multiply(BigDecimal.valueOf(6));
                BigDecimal newEf6 = ef.add(extra6);
                BigDecimal efAfter6 = newEf6.subtract(price);
                String v6 = quickVerdict(surplus, BigDecimal.ZERO, efAfter6, recommendedEF, false, BigDecimal.ZERO);
                int conf6 = computeConfidence(v6, BigDecimal.ZERO, efAfter6, expenses, surplus, income);

                List<TradeoffDto> tradeoffs6 = tradeoffEngine.forScenario(
                        "Wait 6 Months", null, null, null, null,
                        efAfter6, expenses, surplus, income, false);
                List<String> whyThis6 = explainEngine.whyThis(v6, BigDecimal.valueOf(conf6), BigDecimal.ZERO,
                        efAfter6, expenses, surplus, income, "Wait 6 Months");

                list.add(ScenarioDto.builder()
                        .label("Wait 6 Months")
                        .verdict(v6)
                        .confidence(conf6)
                        .recommendationStrength(RecommendationStrength.from(conf6).name())
                        .monthlyEmi(null)
                        .totalInterest(null)
                        .totalCost(price)
                        .summary("Save ₹" + extra6.setScale(0, RoundingMode.HALF_UP) + " — emergency fund safely above 6-month floor")
                        .isRecommended(false)
                        .whyThis(whyThis6)
                        .whyNot(new ArrayList<>())
                        .tradeoffs(tradeoffs6)
                        .build());
            }
        }

        // Scenario 5: Delay until 6-month emergency fund (always shown)
        {
            BigDecimal gap = recommendedEF.subtract(ef).max(BigDecimal.ZERO);
            BigDecimal monthlySave = surplus.multiply(SAVE_RATE_OF_SURPLUS).max(BigDecimal.ONE);
            int months5 = gap.compareTo(BigDecimal.ZERO) > 0
                    ? gap.divide(monthlySave, 0, RoundingMode.CEILING).intValue()
                    : 0;
            BigDecimal newEf5 = ef.add(monthlySave.multiply(BigDecimal.valueOf(months5)));
            BigDecimal cashOut5 = isLoan ? downPayment : price;
            BigDecimal efAfter5 = newEf5.subtract(cashOut5);
            BigDecimal emi5 = currentEmi;
            BigDecimal dti5 = calcDti(existingEmi.add(emi5), income);
            BigDecimal surplusAfter5 = surplus.subtract(emi5).max(BigDecimal.ZERO);
            String v5 = quickVerdict(surplus, dti5, efAfter5, recommendedEF, isLoan, emi5);
            int conf5 = Math.min(95, computeConfidence(v5, dti5, efAfter5, expenses, surplusAfter5, income) + 5);
            BigDecimal totalInterest5 = (isLoan && tenure > 0) ? emi5.multiply(BigDecimal.valueOf(tenure)).subtract(loanAmount).max(BigDecimal.ZERO) : BigDecimal.ZERO;
            String scenarioLabel = months5 <= 0 ? "EF Already Adequate" : "Build Safety Net First (" + months5 + " mo)";
            String summary5 = months5 <= 0
                    ? "Your emergency fund meets the 6-month target — lowest financial risk."
                    : "Save ₹" + monthlySave.setScale(0, RoundingMode.HALF_UP) + "/mo for " + months5 + " months, then buy with confidence.";

            List<TradeoffDto> tradeoffs5 = tradeoffEngine.forScenario(
                    scenarioLabel, isLoan ? emi5 : null, baselineEmi,
                    (isLoan && tenure > 0) ? totalInterest5 : null, baselineInterest,
                    efAfter5, expenses, surplusAfter5, income, false);
            List<String> whyThis5 = explainEngine.whyThis(
                    months5 <= 0 ? v5 : "SAFE_TO_BUY", BigDecimal.valueOf(conf5), dti5,
                    efAfter5, expenses, surplusAfter5, income, scenarioLabel);

            list.add(ScenarioDto.builder()
                    .label(scenarioLabel)
                    .verdict(months5 <= 0 ? v5 : "SAFE_TO_BUY")
                    .confidence(conf5)
                    .recommendationStrength(RecommendationStrength.from(conf5).name())
                    .monthlyEmi(isLoan ? emi5.setScale(0, RoundingMode.CEILING) : null)
                    .totalInterest((isLoan && tenure > 0) ? totalInterest5.setScale(0, RoundingMode.HALF_UP) : null)
                    .totalCost((isLoan && tenure > 0) ? price.add(totalInterest5).setScale(0, RoundingMode.HALF_UP) : price)
                    .summary(summary5)
                    .isRecommended(false)
                    .whyThis(whyThis5)
                    .whyNot(new ArrayList<>())
                    .tradeoffs(tradeoffs5)
                    .build());
        }

        // Mark highest-confidence as recommended
        list.stream()
                .max(Comparator.comparingInt(ScenarioDto::getConfidence))
                .ifPresent(s -> s.setRecommended(true));

        // Find recommended label for whyNot generation
        String recommendedLabel = list.stream()
                .filter(ScenarioDto::isRecommended)
                .map(ScenarioDto::getLabel)
                .findFirst()
                .orElse("unknown");

        // Fill in whyNot for non-recommended scenarios
        for (ScenarioDto scenario : list) {
            if (!scenario.isRecommended()) {
                // Compute the efAfter and surplusAfter for this specific scenario
                // We approximate using the scenario's own confidence and verdict
                BigDecimal scenarioDtiApprox = BigDecimal.ZERO;
                BigDecimal scenarioEfApprox = BigDecimal.ZERO;
                BigDecimal scenarioSurplusApprox = BigDecimal.ZERO;

                // Use scenario EMI to re-derive approximate values
                BigDecimal sEmi = scenario.getMonthlyEmi() != null ? scenario.getMonthlyEmi() : BigDecimal.ZERO;
                scenarioSurplusApprox = surplus.subtract(sEmi).max(BigDecimal.ZERO);
                scenarioDtiApprox = calcDti(existingEmi.add(sEmi), income);
                BigDecimal sCashOut = isLoan ? downPayment : price;
                scenarioEfApprox = ef.subtract(sCashOut).max(BigDecimal.ZERO);

                List<String> whyNot = explainEngine.whyNot(
                        scenario.getVerdict(), scenario.getConfidence(),
                        scenarioDtiApprox, scenarioEfApprox, expenses,
                        scenarioSurplusApprox, income,
                        false, recommendedLabel, scenario.getTotalInterest());
                scenario.setWhyNot(whyNot);
            }
        }

        return list;
    }

    // ── Math helpers ──────────────────────────────────────────────────────────

    private BigDecimal calcEmi(BigDecimal principal, BigDecimal annualRatePercent, int months) {
        if (principal.compareTo(BigDecimal.ZERO) <= 0 || months <= 0) return BigDecimal.ZERO;
        if (annualRatePercent == null || annualRatePercent.compareTo(BigDecimal.ZERO) == 0) {
            return principal.divide(BigDecimal.valueOf(months), 0, RoundingMode.CEILING);
        }
        BigDecimal r = annualRatePercent.divide(BigDecimal.valueOf(1200), CALC_SCALE, RoundingMode.HALF_UP);
        BigDecimal pow = BigDecimal.ONE.add(r).pow(months);
        BigDecimal numerator = principal.multiply(r).multiply(pow);
        BigDecimal denominator = pow.subtract(BigDecimal.ONE);
        return numerator.divide(denominator, 0, RoundingMode.CEILING);
    }

    private BigDecimal reverseEmi(BigDecimal maxEmi, BigDecimal annualRatePercent, int months) {
        if (maxEmi.compareTo(BigDecimal.ZERO) <= 0 || months <= 0) return BigDecimal.ZERO;
        if (annualRatePercent == null || annualRatePercent.compareTo(BigDecimal.ZERO) == 0) {
            return maxEmi.multiply(BigDecimal.valueOf(months));
        }
        BigDecimal r = annualRatePercent.divide(BigDecimal.valueOf(1200), CALC_SCALE, RoundingMode.HALF_UP);
        BigDecimal pow = BigDecimal.ONE.add(r).pow(months);
        BigDecimal numerator = maxEmi.multiply(pow.subtract(BigDecimal.ONE));
        BigDecimal denominator = r.multiply(pow);
        return numerator.divide(denominator, 0, RoundingMode.FLOOR);
    }

    private BigDecimal calcDti(BigDecimal totalDebt, BigDecimal income) {
        if (income.compareTo(BigDecimal.ZERO) <= 0) return BigDecimal.ZERO;
        return totalDebt.divide(income, CALC_SCALE, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100)).setScale(1, RoundingMode.HALF_UP);
    }

    private String quickVerdict(BigDecimal surplus, BigDecimal dtiRatio, BigDecimal efAfterPurchase,
                                 BigDecimal recommendedEF, boolean isLoan, BigDecimal newEmi) {
        if (surplus.compareTo(BigDecimal.ZERO) <= 0) return "DONT_BUY";
        if (dtiRatio.compareTo(BigDecimal.valueOf(50)) > 0) return "DONT_BUY";
        if (isLoan && newEmi.compareTo(surplus) >= 0) return "DONT_BUY";
        if (efAfterPurchase.compareTo(recommendedEF) < 0) return "WAIT_AND_SAVE";
        if (dtiRatio.compareTo(BigDecimal.valueOf(40)) > 0) return "WAIT_AND_SAVE";
        return "SAFE_TO_BUY";
    }
}
