package com.pennywise.mapper;

import com.pennywise.domain.decision.BehavioralContextData;
import com.pennywise.domain.decision.DecisionData;
import com.pennywise.domain.decision.DecisionResponse;
import com.pennywise.domain.decision.DecisionVersioning;
import com.pennywise.domain.decision.ExplanationData;
import com.pennywise.domain.decision.GoalImpactData;
import com.pennywise.domain.decision.PartnerRecommendation;
import com.pennywise.domain.decision.RecommendationData;
import com.pennywise.domain.decision.TrustData;
import com.pennywise.dto.decision.PartnerOption;
import com.pennywise.dto.decision.TodayDecisionResponse;
import com.pennywise.policy.FinancialPolicy;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/**
 * Maps the legacy TodayDecisionResponse DTO into the canonical DecisionResponse envelope.
 * TodayDecisionService is untouched — only the controller delegates to this mapper.
 */
@Component
public class DecisionResponseMapper {

    private static final DecisionVersioning CURRENT_VERSIONING = new DecisionVersioning(
            "2.0.0", "v1-rule-based", "1.0", "uncalibrated", "stub");

    public DecisionResponse fromToday(TodayDecisionResponse today) {
        return new DecisionResponse(
                today.decisionId(),
                CURRENT_VERSIONING,
                buildDecision(today),
                buildExplanation(today),
                new BehavioralContextData("uncalibrated", null, null, null, null),
                buildPartners(today.partnerOptions()),
                buildTrust(today),
                Instant.now().toString());
    }

    // ── Private builders ──────────────────────────────────────────────────────

    private DecisionData buildDecision(TodayDecisionResponse today) {
        var rec = today.recommendedAction();
        var impact = today.impact();
        return new DecisionData(
                today.decisionId().toUpperCase().replace("-", "_"),
                today.headline(),
                today.subheadline(),
                today.priority(),
                today.icon(),
                new RecommendationData(
                        rec.actionType(),
                        rec.monthlyAmount(),
                        rec.instrument(),
                        rec.timeline(),
                        FinancialPolicy.DEFAULT_CONFIDENCE_V1),
                new GoalImpactData(
                        impact.healthScoreCurrent(),
                        impact.healthScoreAfter(),
                        impact.goalSuccessRateCurrent(),
                        impact.goalSuccessRateAfter(),
                        impact.runwayMonthsAdded(),
                        impact.monthlySavingsIncrease()));
    }

    private ExplanationData buildExplanation(TodayDecisionResponse today) {
        return new ExplanationData(
                today.headline(),
                today.subheadline(),
                today.reasons(),
                List.of(),
                List.of(),
                List.of(),
                List.of(),
                List.of(
                        "Full analysis requires Account Aggregator data",
                        "Behavioral parameters are uncalibrated — suggestions improve with usage"),
                List.of(
                        "Transaction history available",
                        "Goals data present",
                        "Monthly salary configured"));
    }

    private List<PartnerRecommendation> buildPartners(List<PartnerOption> options) {
        var result = new ArrayList<PartnerRecommendation>(options.size());
        for (int i = 0; i < options.size(); i++) {
            var opt = options.get(i);
            boolean taxBenefit = opt.partner().toLowerCase().contains("ppf")
                    || opt.partner().toLowerCase().contains("elss")
                    || opt.partner().toLowerCase().contains("nps");
            String riskLevel = opt.rate() < 8.0 ? "LOW" : opt.rate() < 12.0 ? "MEDIUM" : "HIGH";
            String programId = opt.partner().toLowerCase()
                    .replaceAll("[^a-z0-9]", "_") + "_" + i;
            result.add(new PartnerRecommendation(
                    programId,
                    opt.partner(),
                    opt.feature().isBlank() ? "Financial Product" : opt.feature(),
                    String.format("%.2f%%", opt.rate()),
                    "Annual return",
                    opt.rate(),
                    opt.minAmount(),
                    riskLevel,
                    taxBenefit,
                    i + 1,
                    Math.max(0.50, 0.92 - (i * 0.06)),
                    "Matched to your current financial goal",
                    FinancialPolicy.FIDUCIARY_STATEMENT,
                    opt.ctaLabel().isBlank() ? "View" : opt.ctaLabel()));
        }
        return result;
    }

    private TrustData buildTrust(TodayDecisionResponse today) {
        String confidenceLevel = "HIGH".equals(today.priority()) ? "HIGH" : "MEDIUM";
        return new TrustData(
                "v1-rule-based",
                Instant.now().toString(),
                List.of("Transaction history", "Goals data", "Monthly salary"),
                List.of("Account Aggregator", "Insurance data", "Investment portfolio"),
                confidenceLevel,
                FinancialPolicy.COMMISSION_POLICY,
                FinancialPolicy.FIDUCIARY_STATEMENT);
    }
}
