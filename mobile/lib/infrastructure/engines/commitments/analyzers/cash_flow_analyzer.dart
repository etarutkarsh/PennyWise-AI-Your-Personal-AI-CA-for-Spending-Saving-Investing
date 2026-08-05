import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/cash_flow_waterfall.dart';
import '../../../../domain/shared/analyzer_result.dart';

class CashFlowAnalyzer {
  const CashFlowAnalyzer();

  AnalyzerResult<CashFlowWaterfall> analyze(
    double monthlyIncome,
    Map<CommitmentCategory, List<DetectedCommitment>> mandatesByCategory,
    List<DetectedCommitment> subscriptions,
  ) {
    final startedAt = DateTime.now();

    final criticalCommitments = (mandatesByCategory[CommitmentCategory.critical] ?? [])
        .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final investmentCommitments =
        (mandatesByCategory[CommitmentCategory.investment] ?? [])
            .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final lifestyleCommitments =
        (mandatesByCategory[CommitmentCategory.lifestyle] ?? [])
            .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final optionalMandates =
        (mandatesByCategory[CommitmentCategory.optional] ?? [])
            .fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final subscriptionCommitments =
        subscriptions.fold<double>(0, (s, c) => s + c.monthlyEquivalent) +
            optionalMandates;

    final totalCommitments = criticalCommitments +
        investmentCommitments +
        lifestyleCommitments +
        subscriptionCommitments;

    final surplus = monthlyIncome - totalCommitments;
    final suggestedEmergencyContribution =
        (surplus * 0.15).clamp(0.0, 5000.0);
    final availableDiscretionary = surplus - suggestedEmergencyContribution;

    final commitmentRatio = monthlyIncome > 0
        ? (totalCommitments / monthlyIncome).clamp(0.0, 1.0)
        : 0.0;
    final isHealthy = commitmentRatio < 0.60 && availableDiscretionary > 0;

    // Build waterfall steps
    var running = monthlyIncome;
    final steps = <CashFlowWaterfallStep>[];

    steps.add(CashFlowWaterfallStep(
      label: 'Monthly Income',
      amount: monthlyIncome,
      runningBalance: running,
      isDeduction: false,
      note: 'Gross monthly take-home',
    ));

    if (criticalCommitments > 0) {
      running -= criticalCommitments;
      steps.add(CashFlowWaterfallStep(
        label: 'Critical Obligations',
        amount: criticalCommitments,
        runningBalance: running,
        isDeduction: true,
        note: 'EMI, rent, essential insurance, tax',
      ));
    }

    if (investmentCommitments > 0) {
      running -= investmentCommitments;
      steps.add(CashFlowWaterfallStep(
        label: 'Investment Commitments',
        amount: investmentCommitments,
        runningBalance: running,
        isDeduction: true,
        note: 'SIP, RD, NPS, savings',
      ));
    }

    if (lifestyleCommitments > 0) {
      running -= lifestyleCommitments;
      steps.add(CashFlowWaterfallStep(
        label: 'Lifestyle Commitments',
        amount: lifestyleCommitments,
        runningBalance: running,
        isDeduction: true,
        note: 'Utilities, gym, education, telecom',
      ));
    }

    if (subscriptionCommitments > 0) {
      running -= subscriptionCommitments;
      steps.add(CashFlowWaterfallStep(
        label: 'Subscriptions',
        amount: subscriptionCommitments,
        runningBalance: running,
        isDeduction: true,
        note: 'Streaming, SaaS, memberships',
      ));
    }

    steps.add(CashFlowWaterfallStep(
      label: 'Surplus',
      amount: surplus.abs(),
      runningBalance: running,
      isDeduction: surplus < 0,
      note: surplus >= 0 ? 'Available after commitments' : 'Commitment shortfall',
    ));

    if (suggestedEmergencyContribution > 0) {
      running -= suggestedEmergencyContribution;
      steps.add(CashFlowWaterfallStep(
        label: 'Emergency Fund (suggested)',
        amount: suggestedEmergencyContribution,
        runningBalance: running,
        isDeduction: true,
        note: '15% of surplus, capped at ₹5,000',
      ));
    }

    steps.add(CashFlowWaterfallStep(
      label: 'Discretionary',
      amount: availableDiscretionary.abs(),
      runningBalance: availableDiscretionary,
      isDeduction: availableDiscretionary < 0,
      note: 'Free to spend or invest further',
    ));

    final waterfall = CashFlowWaterfall(
      monthlyIncome: monthlyIncome,
      criticalCommitments: criticalCommitments,
      investmentCommitments: investmentCommitments,
      lifestyleCommitments: lifestyleCommitments,
      subscriptionCommitments: subscriptionCommitments,
      surplus: surplus,
      suggestedEmergencyContribution: suggestedEmergencyContribution,
      availableDiscretionary: availableDiscretionary,
      steps: steps,
      isHealthy: isHealthy,
    );

    return AnalyzerResult.of(
      analyzerId: 'cash_flow_analyzer',
      result: waterfall,
      confidence: monthlyIncome > 0 ? 0.90 : 0.30,
      startedAt: startedAt,
      limitations: monthlyIncome <= 0
          ? ['Monthly income not configured — cash flow analysis incomplete']
          : [],
    );
  }
}
