import 'package:pennywise_ai/domain/decision/behavioral_context.dart';
import 'package:pennywise_ai/domain/decision/decision.dart';
import 'package:pennywise_ai/domain/decision/decision_audit.dart';
import 'package:pennywise_ai/domain/decision/decision_response.dart';
import 'package:pennywise_ai/domain/decision/decision_type.dart';
import 'package:pennywise_ai/domain/decision/explanation.dart';
import 'package:pennywise_ai/domain/decision/goal_impact.dart';
import 'package:pennywise_ai/domain/decision/next_action.dart';
import 'package:pennywise_ai/domain/decision/recommendation.dart';
import 'package:pennywise_ai/domain/decision/trust_metadata.dart';
import 'package:pennywise_ai/domain/finance/financial_state.dart';
import 'package:pennywise_ai/domain/partner/financial_instrument.dart';
import 'package:pennywise_ai/domain/value_objects/currency.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';
import 'package:pennywise_ai/domain/value_objects/money.dart';
import 'package:pennywise_ai/domain/value_objects/time_horizon.dart';
import 'package:pennywise_ai/features/decisions/data/models/today_decision_model.dart';
import 'partner_mapper.dart';

class DecisionMapper {
  const DecisionMapper(this._partnerMapper);
  final PartnerMapper _partnerMapper;

  DecisionResponse fromModel(TodayDecisionModel model) {
    final decisionId = DecisionId(
      model.decisionId.isNotEmpty
          ? model.decisionId
          : 'local-${DateTime.now().millisecondsSinceEpoch}',
    );

    final recommendation = Recommendation(
      id: RecommendationId('${decisionId.value}-rec'),
      action: _parseAction(model.recommendedAction.actionType),
      monthlyAmount: Money(
        amount: model.recommendedAction.monthlyAmount,
        currency: Currency.inr,
      ),
      instrument: _parseInstrument(model.recommendedAction.instrument),
      horizon: TimeHorizon.fromLabel(model.recommendedAction.timeline),
    );

    final explanation = Explanation(
      headline: model.headline,
      summary: model.subheadline,
      because: model.reasons,
      evidence: const [],
      assumptions: const [],
      alternatives: const [],
      whyNot: const [],
      tradeoffs: const [],
      confidenceDrivers: const [],
      limitations: const ['Full explanation requires backend v2'],
      engineTrace: const ['TodayDecisionEngine v1'],
    );

    final goalImpact = [
      GoalImpact(
        goalId: const GoalId('primary'),
        goalName: 'Primary Goal',
        currentHealthScore: model.impact.healthScoreCurrent,
        projectedHealthScore: model.impact.healthScoreAfter,
        successProbabilityDelta:
            (model.impact.goalSuccessRateAfter -
                    model.impact.goalSuccessRateCurrent) /
                100.0,
      ),
    ];

    final trust = TrustMetadata(
      algorithmVersion: 'decision-engine-v1',
      decisionDate: DateTime.now(),
      dataFreshness: const Duration(minutes: 15),
      missingData: const ['Account Aggregator', 'Insurance data'],
      commissionConflict: false,
      verifiedSources: const ['Transaction history', 'Goals', 'Salary'],
      fiduciaryStatement: TrustMetadata.defaultFiduciaryStatement,
    );

    final audit = DecisionAudit(
      eventId: EventId('evt-${decisionId.value}'),
      sequenceNumber: 0,
      replayable: false,
      engineTrace: const [
        EngineContribution(
          engineName: 'TodayDecisionEngine',
          version: 'v1',
          outputSummary: 'Rule-based decision',
          durationMs: 0,
        ),
      ],
    );

    final decision = Decision(
      id: decisionId,
      correlationId: CorrelationId('corr-${decisionId.value}'),
      sessionId: const SessionId('sess-current'),
      eventId: EventId('evt-${decisionId.value}'),
      userId: const UserId('current'),
      type: _parseDecisionType(model.decisionId),
      priority: model.priority,
      financialState: FinancialState.stabilize,
      generatedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
      engineVersion: 'decision-engine-v1',
      recommendation: recommendation,
      explanation: explanation,
      goalImpacts: goalImpact,
      behavioralContext: BehavioralContext.uncalibrated(),
      trust: trust,
      audit: audit,
      lifecycleState: DecisionLifecycleState.generated,
    );

    final partnerPrograms = model.partnerOptions
        .map(_partnerMapper.fromPartnerOptionModel)
        .toList();

    return DecisionResponse(
      decision: decision,
      partnerPrograms: partnerPrograms,
      goalImpacts: goalImpact,
      nextActions: const [
        NextAction(
          type: NextActionType.openPartner,
          label: 'View Options',
        ),
        NextAction(
          type: NextActionType.learn,
          label: 'Learn More',
        ),
      ],
    );
  }

  RecommendedAction _parseAction(String actionType) {
    switch (actionType.toUpperCase()) {
      case 'START_RD':
        return RecommendedAction.startRd;
      case 'START_SIP':
        return RecommendedAction.startSip;
      case 'START_ELSS_SIP':
        return RecommendedAction.startElssSip;
      case 'INCREASE_SIP':
        return RecommendedAction.increaseSavingsRate;
      default:
        return RecommendedAction.startRd;
    }
  }

  FinancialInstrument _parseInstrument(String instrument) {
    switch (instrument.toLowerCase()) {
      case 'recurring deposit':
        return FinancialInstrument.recurringDeposit;
      case 'liquid fund':
      case 'recurring deposit or liquid fund':
        return FinancialInstrument.liquidFund;
      case 'mutual fund sip':
        return FinancialInstrument.indexFundSip;
      case 'elss mutual fund':
        return FinancialInstrument.elssSip;
      default:
        return FinancialInstrument.recurringDeposit;
    }
  }

  DecisionType _parseDecisionType(String decisionId) {
    if (decisionId.contains('emergency') ||
        decisionId.contains('build_emergency')) {
      return DecisionType.buildEmergencyFund;
    }
    if (decisionId.contains('savings') ||
        decisionId.contains('increase_savings')) {
      return DecisionType.increaseSavingsRate;
    }
    if (decisionId.contains('sip') || decisionId.contains('start_goal')) {
      return DecisionType.startGoalSip;
    }
    if (decisionId.contains('tax') || decisionId.contains('optimize')) {
      return DecisionType.optimizeTax;
    }
    return DecisionType.buildEmergencyFund;
  }
}
