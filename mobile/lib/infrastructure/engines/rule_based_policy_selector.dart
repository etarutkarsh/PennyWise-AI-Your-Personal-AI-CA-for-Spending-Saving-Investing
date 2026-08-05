import '../../domain/reasoning/policy/axis_weight_profile.dart';
import '../../domain/reasoning/policy/decision_policy.dart';
import '../../domain/reasoning/policy/lifecycle_stage.dart';
import '../../domain/reasoning/policy/policy_decision.dart';
import '../../domain/reasoning/policy/policy_evolution_rule.dart';
import '../../domain/reasoning/policy/policy_modifier.dart';
import '../../domain/reasoning/policy/policy_selector.dart';
import '../../domain/reasoning/policy/policy_state_record.dart';
import '../../domain/reasoning/policy/policy_thresholds.dart';
import '../../domain/reasoning/policy/user_archetype.dart';
import '../../domain/shared/financial_facts.dart';

/// Rule-based implementation of [PolicySelector].
///
/// Implements 14 named policies covering the 7 user archetypes across all
/// relevant financial maturity states. All 14 weight tables sum to 1.0.
///
/// Selection is deterministic: given the same inputs, always the same output.
/// Priority resolution is explicit — higher [DecisionPolicy.priority] wins.
///
/// Priority table (highest first):
///   100 — RetiredPolicy             (lifecycle override, age ≥ 60)
///    90 — PreRetirementPolicy       (lifecycle override, age 55–59)
///    80 — FreelancerSurvivePolicy   (income volatility crisis)
///    75 — SalariedSurvivePolicy     (EF emergency)
///    70 — BusinessOwnerSurvivePolicy
///    65 — FreelancerStabilizePolicy
///    60 — SalariedStabilizePolicy
///    55 — BusinessOwnerBuildPolicy
///    50 — FreelancerBuildPolicy
///    45 — StudentPolicy
///    40 — SalariedBuildPolicy       (default steady-state)
///    35 — FreelancerOptimizePolicy
///    30 — BusinessOwnerOptimizePolicy
///    20 — SalariedOptimizePolicy
class RuleBasedPolicySelector implements PolicySelector {
  const RuleBasedPolicySelector();

  static const String _kVersion = 'policy-rule-v1';
  static const String _kSchema = '1.0';

  @override
  String get engineVersion => _kVersion;

  // ─── PolicySelector interface ─────────────────────────────────────────────

  @override
  PolicyDecision select({
    required FinancialFacts facts,
    required UserArchetype archetype,
    PolicyStateRecord? existingRecord,
  }) {
    final age = facts.ageYearsValue;
    final stage = LifecycleStage.fromAge(age);
    final efMonths = facts.emergencyFundMonthsValue;
    final debtRatio = facts.debtRatioValue;
    final savingsRate = facts.savingsRateValue;

    // ── Step 1: Lifecycle overrides (highest priority, no archetype bypass) ──
    if (stage == LifecycleStage.retirement) {
      return _makeDecision(
        policy: _retiredPolicy(stage),
        matchedConditions: ['age=$age ≥ 60 → retirement lifecycle override'],
        confidence: 0.95,
        reason: 'Retirement phase (age $age): capital preservation and '
            'sustainable withdrawal strategy active.',
      );
    }
    if (stage == LifecycleStage.preRetirement) {
      return _makeDecision(
        policy: _preRetirementPolicy(stage),
        matchedConditions: ['age=$age ∈ [55,60) → pre-retirement lifecycle override'],
        confidence: 0.92,
        reason: 'Pre-retirement phase (age $age): de-risking and '
            'retirement buffer building strategy active.',
      );
    }

    // ── Step 2: Archetype + FinancialState selection ──────────────────────────
    final candidates = <_Candidate>[];

    switch (archetype) {
      case UserArchetype.student:
      case UserArchetype.youngProfessional:
        candidates.add(_Candidate(
          policy: _studentPolicy(stage),
          matchedConditions: ['archetype=$archetype'],
          confidence: 0.88,
          reason: 'Student/Young Professional profile: habit formation and '
              'emergency fund building take priority over optimisation.',
        ));

      case UserArchetype.freelancer:
        final policy = _freelancerPolicy(stage, efMonths, debtRatio, savingsRate);
        candidates.add(_Candidate(
          policy: policy,
          matchedConditions: [
            'archetype=freelancer',
            'EF=${efMonths.toStringAsFixed(1)}mo',
            'debtRatio=${debtRatio.toStringAsFixed(2)}',
          ],
          confidence: 0.90,
          reason: _freelancerReason(policy.id, efMonths, debtRatio),
        ));

      case UserArchetype.businessOwner:
        final policy = _businessOwnerPolicy(stage, efMonths, debtRatio, savingsRate);
        candidates.add(_Candidate(
          policy: policy,
          matchedConditions: [
            'archetype=businessOwner',
            'EF=${efMonths.toStringAsFixed(1)}mo',
            'debtRatio=${debtRatio.toStringAsFixed(2)}',
          ],
          confidence: 0.88,
          reason: _businessOwnerReason(policy.id, efMonths, debtRatio),
        ));

      case UserArchetype.preRetiree:
        candidates.add(_Candidate(
          policy: _preRetirementPolicy(stage),
          matchedConditions: ['archetype=preRetiree'],
          confidence: 0.90,
          reason: 'Pre-retiree profile: transitioning from accumulation to '
              'preservation and de-risking.',
        ));

      case UserArchetype.retiree:
        candidates.add(_Candidate(
          policy: _retiredPolicy(stage),
          matchedConditions: ['archetype=retiree'],
          confidence: 0.95,
          reason: 'Retiree profile: capital preservation and sustainable '
              'withdrawal strategy active.',
        ));

      case UserArchetype.salariedWithFamily:
        final policy = _salariedPolicy(stage, efMonths, debtRatio, savingsRate);
        candidates.add(_Candidate(
          policy: policy,
          matchedConditions: [
            'archetype=salariedWithFamily',
            'EF=${efMonths.toStringAsFixed(1)}mo',
            'debtRatio=${debtRatio.toStringAsFixed(2)}',
            'savingsRate=${savingsRate.toStringAsFixed(2)}',
          ],
          confidence: 0.88,
          reason: _salariedReason(policy.id, efMonths, debtRatio, savingsRate),
        ));
    }

    if (candidates.isEmpty) {
      // Fallback — should never be reached with complete switch, but satisfies
      // the "always returns a non-null result" invariant.
      return _fallback(stage);
    }

    // ── Step 3: Priority resolution (highest wins) ────────────────────────────
    candidates.sort((a, b) => b.policy.priority.compareTo(a.policy.priority));
    final winner = candidates.first;

    final conflicting = candidates.length > 1
        ? candidates.skip(1).map((c) => c.policy.id).toList()
        : <String>[];

    // ── Step 4: Apply seasonal/behavioral modifiers ───────────────────────────
    var finalPolicy = winner.policy;
    final activeModifiers = <String>[];
    final now = DateTime.now();

    if (now.month == 2 || now.month == 3) {
      finalPolicy = finalPolicy.withModifier(PolicyModifier.taxSeason);
      activeModifiers.add(PolicyModifier.taxSeason.name);
    }
    if (now.month == 10) {
      finalPolicy = finalPolicy.withModifier(PolicyModifier.festiveSeason);
      activeModifiers.add(PolicyModifier.festiveSeason.name);
    }

    return PolicyDecision(
      policy: finalPolicy,
      policyId: finalPolicy.id,
      policyLabel: finalPolicy.name,
      reason: winner.reason,
      matchedConditions: winner.matchedConditions,
      confidence: winner.confidence,
      fallbackUsed: false,
      activeModifiers: activeModifiers,
      conflictingPolicies: conflicting,
      conflictResolution: conflicting.isNotEmpty
          ? '${winner.policy.id} wins over ${conflicting.join(', ')} by priority'
          : null,
    );
  }

  @override
  List<String> get allPolicyIds => [
        'student_v1',
        'salaried_survive_v1',
        'salaried_stabilize_v1',
        'salaried_build_v1',
        'salaried_optimize_v1',
        'freelancer_survive_v1',
        'freelancer_stabilize_v1',
        'freelancer_build_v1',
        'freelancer_optimize_v1',
        'business_owner_survive_v1',
        'business_owner_build_v1',
        'business_owner_optimize_v1',
        'pre_retirement_v1',
        'retired_v1',
      ];

  @override
  List<String> get evolutionEdges => [
        'salaried_survive_v1 -> salaried_stabilize_v1',
        'salaried_stabilize_v1 -> salaried_build_v1',
        'salaried_build_v1 -> salaried_optimize_v1',
        'salaried_optimize_v1 -> pre_retirement_v1',
        'freelancer_survive_v1 -> freelancer_stabilize_v1',
        'freelancer_stabilize_v1 -> freelancer_build_v1',
        'freelancer_build_v1 -> freelancer_optimize_v1',
        'freelancer_optimize_v1 -> pre_retirement_v1',
        'business_owner_survive_v1 -> business_owner_build_v1',
        'business_owner_build_v1 -> business_owner_optimize_v1',
        'business_owner_optimize_v1 -> pre_retirement_v1',
        'student_v1 -> salaried_build_v1',
        'pre_retirement_v1 -> retired_v1',
        // protective downgrades
        'salaried_build_v1 -> salaried_stabilize_v1',
        'salaried_optimize_v1 -> salaried_build_v1',
      ];

  // ─── Named policy factories ───────────────────────────────────────────────

  DecisionPolicy _studentPolicy(LifecycleStage stage) => DecisionPolicy(
        id: 'student_v1',
        name: 'Student',
        archetype: UserArchetype.student,
        lifecycleStage: stage,
        priority: 45,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.20,
          liquidity: 0.25,
          goalImpact: 0.30,
          behavior: 0.20,
          taxes: 0.02,
          opportunityCost: 0.03,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 3.0,
          minSavingsRate: 0.05,
          safeDebtRatio: 0.20,
          criticalDebtRatio: 0.35,
          taxEfficiencyTarget: 0.30,
          minOpportunityCostRate: 0.02,
          behaviorMinimumConsistency: 0.30,
        ),
        evolutionRules: const [
          PolicyEvolutionRule(
            triggerId: 'student_to_salaried_build',
            description: 'Student enters employment with stable income',
            fromPolicyId: 'student_v1',
            toPolicyId: 'salaried_build_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 3.0,
                sustainedDays: 30,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'You\'ve built your emergency fund. Ready to start systematic wealth building.',
          ),
        ],
        selectionReason:
            'Student/Young Professional: habit formation dominates optimisation',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Age 18–26, no or stipend-level income, in education',
          activationDescription: 'archetype=student or age < 27 with no income history',
          exitDescription: 'emergencyFundMonths ≥ 3.0 sustained for 30 days',
          evolutionDescription: 'Graduates to SalariedBuild when employment and EF established',
        ),
      );

  // ── Salaried policies ──────────────────────────────────────────────────────

  DecisionPolicy _salariedPolicy(
    LifecycleStage stage,
    double efMonths,
    double debtRatio,
    double savingsRate,
  ) {
    if (efMonths < 3.0 || debtRatio > 0.50) return _salariedSurvive(stage);
    if (efMonths < 6.0 || debtRatio > 0.35) return _salariedStabilize(stage);
    if (savingsRate >= 0.22 && efMonths >= 6.0 && debtRatio <= 0.25) {
      return _salariedOptimize(stage);
    }
    return _salariedBuild(stage);
  }

  DecisionPolicy _salariedSurvive(LifecycleStage stage) => DecisionPolicy(
        id: 'salaried_survive_v1',
        name: 'Salaried — Survive',
        archetype: UserArchetype.salariedWithFamily,
        lifecycleStage: stage,
        priority: 75,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.30,
          liquidity: 0.35,
          goalImpact: 0.15,
          behavior: 0.12,
          taxes: 0.03,
          opportunityCost: 0.05,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 6.0,
          minSavingsRate: 0.10,
          safeDebtRatio: 0.35,
          criticalDebtRatio: 0.50,
          taxEfficiencyTarget: 0.40,
          minOpportunityCostRate: 0.05,
          behaviorMinimumConsistency: 0.35,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'salaried_survive_to_stabilize',
            description: 'Emergency fund reaches 3-month partial safety net',
            fromPolicyId: 'salaried_survive_v1',
            toPolicyId: 'salaried_stabilize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 3.0,
                sustainedDays: 30,
              ),
              PolicyCondition(
                factKey: 'healthScore',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 45,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'You\'ve built a 3-month safety net. Now it\'s time to tackle any high-interest debt.',
          ),
        ],
        selectionReason:
            'Salaried Survive: EF < 3 months or debt ratio > 50% — foundation first',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Salaried employee with EF < 3 months or critical debt',
          activationDescription: 'emergencyFundMonths < 3.0 OR debtRatio > 0.50',
          exitDescription: 'emergencyFundMonths ≥ 3.0 sustained 30d AND healthScore ≥ 45',
          evolutionDescription: 'Graduates to SalariedStabilize',
        ),
      );

  DecisionPolicy _salariedStabilize(LifecycleStage stage) => DecisionPolicy(
        id: 'salaried_stabilize_v1',
        name: 'Salaried — Stabilise',
        archetype: UserArchetype.salariedWithFamily,
        lifecycleStage: stage,
        priority: 60,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.35,
          liquidity: 0.25,
          goalImpact: 0.18,
          behavior: 0.12,
          taxes: 0.04,
          opportunityCost: 0.06,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 6.0,
          minSavingsRate: 0.12,
          safeDebtRatio: 0.35,
          criticalDebtRatio: 0.50,
          taxEfficiencyTarget: 0.40,
          minOpportunityCostRate: 0.05,
          behaviorMinimumConsistency: 0.35,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'salaried_stabilize_to_build',
            description: 'Full EF achieved, debt under control',
            fromPolicyId: 'salaried_stabilize_v1',
            toPolicyId: 'salaried_build_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 6.0,
                sustainedDays: 30,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.30,
                sustainedDays: 30,
              ),
              PolicyCondition(
                factKey: 'savingsRate',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.12,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Your foundation is solid — 6-month emergency fund, manageable debt. Ready for systematic wealth building.',
          ),
        ],
        selectionReason:
            'Salaried Stabilise: partial EF or moderate debt — debt elimination before investment',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Salaried with 3–6 months EF and/or moderate debt',
          activationDescription: 'emergencyFundMonths ∈ [3, 6) OR debtRatio ∈ (0.35, 0.50]',
          exitDescription:
              'emergencyFundMonths ≥ 6.0 sustained 30d AND debtRatio ≤ 0.30 AND savingsRate ≥ 0.12',
          evolutionDescription: 'Graduates to SalariedBuild',
        ),
      );

  DecisionPolicy _salariedBuild(LifecycleStage stage) => DecisionPolicy(
        id: 'salaried_build_v1',
        name: 'Salaried — Build',
        archetype: UserArchetype.salariedWithFamily,
        lifecycleStage: stage,
        priority: 40,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.28,
          liquidity: 0.22,
          goalImpact: 0.20,
          behavior: 0.12,
          taxes: 0.08,
          opportunityCost: 0.10,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 6.0,
          minSavingsRate: 0.15,
          safeDebtRatio: 0.40,
          criticalDebtRatio: 0.50,
          taxEfficiencyTarget: 0.70,
          minOpportunityCostRate: 0.10,
          behaviorMinimumConsistency: 0.40,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'salaried_build_to_optimize',
            description: 'Full wealth-building foundation with strong tax efficiency',
            fromPolicyId: 'salaried_build_v1',
            toPolicyId: 'salaried_optimize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 6.0,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.25,
              ),
              PolicyCondition(
                factKey: 'savingsRate',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.22,
              ),
              PolicyCondition(
                factKey: 'taxEfficiency',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.75,
              ),
              PolicyCondition(
                factKey: 'healthScore',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 72,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'You\'ve achieved consistent wealth building with good tax efficiency. Time to optimise for maximum long-term compounding.',
          ),
          const PolicyEvolutionRule(
            triggerId: 'build_to_stabilize_ef_collapse',
            description: 'Emergency fund has collapsed below 2 months',
            fromPolicyId: 'salaried_build_v1',
            toPolicyId: 'salaried_stabilize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.lessThan,
                threshold: 2.0,
                sustainedDays: 7,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Your emergency fund has dropped below 2 months. Rebuilding it takes priority over investments.',
            isProtectiveDowngrade: true,
          ),
        ],
        selectionReason:
            'Salaried Build: solid foundation — systematic wealth building phase',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Salaried with 6+ months EF and manageable debt',
          activationDescription:
              'emergencyFundMonths ≥ 6.0 AND debtRatio ≤ 0.35 AND savingsRate < 0.22',
          exitDescription:
              'EF ≥ 6mo, debtRatio ≤ 0.25, savingsRate ≥ 0.22, taxEfficiency ≥ 0.75, healthScore ≥ 72',
          evolutionDescription: 'Graduates to SalariedOptimize',
        ),
      );

  DecisionPolicy _salariedOptimize(LifecycleStage stage) => DecisionPolicy(
        id: 'salaried_optimize_v1',
        name: 'Salaried — Optimise',
        archetype: UserArchetype.salariedWithFamily,
        lifecycleStage: stage,
        priority: 20,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.20,
          liquidity: 0.15,
          goalImpact: 0.18,
          behavior: 0.10,
          taxes: 0.17,
          opportunityCost: 0.20,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 6.0,
          minSavingsRate: 0.20,
          safeDebtRatio: 0.35,
          criticalDebtRatio: 0.45,
          taxEfficiencyTarget: 0.90,
          minOpportunityCostRate: 0.20,
          behaviorMinimumConsistency: 0.50,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'optimize_to_build_debt_spike',
            description: 'Debt ratio has risen to wealth-compromising level',
            fromPolicyId: 'salaried_optimize_v1',
            toPolicyId: 'salaried_build_v1',
            conditions: [
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.greaterThan,
                threshold: 0.50,
                sustainedDays: 14,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Your EMI-to-income ratio has risen significantly. Addressing this takes priority over optimisation.',
            isProtectiveDowngrade: true,
          ),
        ],
        selectionReason:
            'Salaried Optimise: strong foundation — maximising tax efficiency and compounding',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription:
              'Salaried with 6+ months EF, low debt, 22%+ savings rate, 75%+ tax efficiency',
          activationDescription:
              'savingsRate ≥ 0.22 AND efMonths ≥ 6.0 AND debtRatio ≤ 0.25',
          exitDescription: 'debtRatio > 0.50 sustained 14 days → protective downgrade',
          evolutionDescription: 'Protective downgrade to SalariedBuild on debt spike',
        ),
      );

  // ── Freelancer policies ───────────────────────────────────────────────────

  DecisionPolicy _freelancerPolicy(
    LifecycleStage stage,
    double efMonths,
    double debtRatio,
    double savingsRate,
  ) {
    if (efMonths < 4.0 || debtRatio > 0.40) return _freelancerSurvive(stage);
    if (efMonths < 9.0 || debtRatio > 0.30) return _freelancerStabilize(stage);
    if (savingsRate >= 0.18 && efMonths >= 9.0 && debtRatio <= 0.25) {
      return _freelancerOptimize(stage);
    }
    return _freelancerBuild(stage);
  }

  DecisionPolicy _freelancerSurvive(LifecycleStage stage) => DecisionPolicy(
        id: 'freelancer_survive_v1',
        name: 'Freelancer — Survive',
        archetype: UserArchetype.freelancer,
        lifecycleStage: stage,
        priority: 80,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.42,
          liquidity: 0.30,
          goalImpact: 0.12,
          behavior: 0.10,
          taxes: 0.03,
          opportunityCost: 0.03,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.10,
          safeDebtRatio: 0.25,
          criticalDebtRatio: 0.40,
          taxEfficiencyTarget: 0.30,
          minOpportunityCostRate: 0.03,
          behaviorMinimumConsistency: 0.25,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'freelancer_survive_to_stabilize',
            description: 'Freelancer achieves partial EF with consistent income',
            fromPolicyId: 'freelancer_survive_v1',
            toPolicyId: 'freelancer_stabilize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 4.0,
                sustainedDays: 45,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'You\'ve shown consistent income and built a partial safety net. Ready to address any high-cost debt.',
          ),
        ],
        selectionReason:
            'Freelancer Survive: income volatility is the meta-problem — cash flow dominates',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Freelancer with EF < 4 months or debt ratio > 40%',
          activationDescription: 'emergencyFundMonths < 4.0 OR debtRatio > 0.40',
          exitDescription: 'emergencyFundMonths ≥ 4.0 sustained 45 days',
          evolutionDescription: 'Graduates to FreelancerStabilize',
        ),
      );

  DecisionPolicy _freelancerStabilize(LifecycleStage stage) => DecisionPolicy(
        id: 'freelancer_stabilize_v1',
        name: 'Freelancer — Stabilise',
        archetype: UserArchetype.freelancer,
        lifecycleStage: stage,
        priority: 65,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.38,
          liquidity: 0.28,
          goalImpact: 0.12,
          behavior: 0.12,
          taxes: 0.04,
          opportunityCost: 0.06,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.10,
          safeDebtRatio: 0.30,
          criticalDebtRatio: 0.45,
          taxEfficiencyTarget: 0.40,
          minOpportunityCostRate: 0.05,
          behaviorMinimumConsistency: 0.30,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'freelancer_stabilize_to_build',
            description: 'Freelancer eliminates high-cost debt with consistent income',
            fromPolicyId: 'freelancer_stabilize_v1',
            toPolicyId: 'freelancer_build_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 6.0,
                sustainedDays: 30,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.25,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Debt under control and income stabilising. Ready to build systematic wealth.',
          ),
        ],
        selectionReason:
            'Freelancer Stabilise: debt particularly dangerous on irregular income',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Freelancer with 4–9 months EF, moderate debt',
          activationDescription: 'emergencyFundMonths ∈ [4, 9) OR debtRatio ∈ (0.30, 0.40]',
          exitDescription:
              'emergencyFundMonths ≥ 6.0 sustained 30d AND debtRatio ≤ 0.25',
          evolutionDescription: 'Graduates to FreelancerBuild',
        ),
      );

  DecisionPolicy _freelancerBuild(LifecycleStage stage) => DecisionPolicy(
        id: 'freelancer_build_v1',
        name: 'Freelancer — Build',
        archetype: UserArchetype.freelancer,
        lifecycleStage: stage,
        priority: 50,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.33,
          liquidity: 0.25,
          goalImpact: 0.16,
          behavior: 0.15,
          taxes: 0.06,
          opportunityCost: 0.05,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.15,
          safeDebtRatio: 0.30,
          criticalDebtRatio: 0.45,
          taxEfficiencyTarget: 0.60,
          minOpportunityCostRate: 0.08,
          behaviorMinimumConsistency: 0.40,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'freelancer_build_to_optimize',
            description: 'Freelancer achieves full 9-month EF with tax compliance',
            fromPolicyId: 'freelancer_build_v1',
            toPolicyId: 'freelancer_optimize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 9.0,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.25,
              ),
              PolicyCondition(
                factKey: 'savingsRate',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.18,
              ),
              PolicyCondition(
                factKey: 'taxEfficiency',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.60,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Exceptional financial discipline for a freelancer. Ready for advanced tax optimisation.',
          ),
        ],
        selectionReason:
            'Freelancer Build: consistent 12-month income achieved — systematic compounding',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Freelancer with 9+ months EF and manageable debt',
          activationDescription:
              'emergencyFundMonths ≥ 9.0 AND debtRatio ≤ 0.30 AND savingsRate < 0.18',
          exitDescription:
              'EF ≥ 9mo, debtRatio ≤ 0.25, savingsRate ≥ 0.18, taxEfficiency ≥ 0.60',
          evolutionDescription: 'Graduates to FreelancerOptimize',
        ),
      );

  DecisionPolicy _freelancerOptimize(LifecycleStage stage) => DecisionPolicy(
        id: 'freelancer_optimize_v1',
        name: 'Freelancer — Optimise',
        archetype: UserArchetype.freelancer,
        lifecycleStage: stage,
        priority: 35,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.25,
          liquidity: 0.20,
          goalImpact: 0.15,
          behavior: 0.13,
          taxes: 0.15,
          opportunityCost: 0.12,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.20,
          safeDebtRatio: 0.30,
          criticalDebtRatio: 0.45,
          taxEfficiencyTarget: 0.85,
          minOpportunityCostRate: 0.15,
          behaviorMinimumConsistency: 0.50,
        ),
        evolutionRules: const [],
        selectionReason:
            'Freelancer Optimise: advance tax efficiency + quarterly compliance active',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription:
              'Freelancer with 9+ months EF, strong income consistency, 60%+ tax compliance',
          activationDescription:
              'emergencyFundMonths ≥ 9.0 AND debtRatio ≤ 0.25 AND savingsRate ≥ 0.18',
          exitDescription: 'No standard exit — apex policy for freelancer archetype',
          evolutionDescription: 'May graduate to PreRetirement on age trigger',
        ),
      );

  // ── Business owner policies ───────────────────────────────────────────────

  DecisionPolicy _businessOwnerPolicy(
    LifecycleStage stage,
    double efMonths,
    double debtRatio,
    double savingsRate,
  ) {
    if (efMonths < 4.0 || debtRatio > 0.45) return _businessOwnerSurvive(stage);
    if (savingsRate >= 0.20 && efMonths >= 9.0 && debtRatio <= 0.30) {
      return _businessOwnerOptimize(stage);
    }
    return _businessOwnerBuild(stage);
  }

  DecisionPolicy _businessOwnerSurvive(LifecycleStage stage) => DecisionPolicy(
        id: 'business_owner_survive_v1',
        name: 'Business Owner — Survive',
        archetype: UserArchetype.businessOwner,
        lifecycleStage: stage,
        priority: 70,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.35,
          liquidity: 0.30,
          goalImpact: 0.12,
          behavior: 0.10,
          taxes: 0.05,
          opportunityCost: 0.08,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.10,
          safeDebtRatio: 0.35,
          criticalDebtRatio: 0.50,
          taxEfficiencyTarget: 0.40,
          minOpportunityCostRate: 0.05,
          behaviorMinimumConsistency: 0.30,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'business_owner_survive_to_build',
            description: 'Business owner achieves personal EF separate from business',
            fromPolicyId: 'business_owner_survive_v1',
            toPolicyId: 'business_owner_build_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 6.0,
                sustainedDays: 30,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.40,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Personal emergency fund established separate from business. Ready to build wealth systematically.',
          ),
        ],
        selectionReason:
            'Business Owner Survive: personal-business finance separation critical',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Business owner with EF < 4 months or debt > 45%',
          activationDescription: 'emergencyFundMonths < 4.0 OR debtRatio > 0.45',
          exitDescription:
              'emergencyFundMonths ≥ 6.0 sustained 30d AND debtRatio ≤ 0.40',
          evolutionDescription: 'Graduates to BusinessOwnerBuild',
        ),
      );

  DecisionPolicy _businessOwnerBuild(LifecycleStage stage) => DecisionPolicy(
        id: 'business_owner_build_v1',
        name: 'Business Owner — Build',
        archetype: UserArchetype.businessOwner,
        lifecycleStage: stage,
        priority: 55,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.25,
          liquidity: 0.20,
          goalImpact: 0.17,
          behavior: 0.12,
          taxes: 0.13,
          opportunityCost: 0.13,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.15,
          safeDebtRatio: 0.35,
          criticalDebtRatio: 0.50,
          taxEfficiencyTarget: 0.75,
          minOpportunityCostRate: 0.12,
          behaviorMinimumConsistency: 0.40,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'business_owner_build_to_optimize',
            description: 'Business owner achieves advanced tax and wealth optimisation',
            fromPolicyId: 'business_owner_build_v1',
            toPolicyId: 'business_owner_optimize_v1',
            conditions: [
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 9.0,
              ),
              PolicyCondition(
                factKey: 'debtRatio',
                operator: ConditionOp.lessThanOrEqual,
                threshold: 0.30,
              ),
              PolicyCondition(
                factKey: 'savingsRate',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 0.18,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Strong personal-business financial separation achieved. Ready for advanced tax and portfolio optimisation.',
          ),
        ],
        selectionReason:
            'Business Owner Build: personal finance stabilised — taxes and OC elevated',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Business owner with 6–9 months EF and manageable debt',
          activationDescription:
              'emergencyFundMonths ≥ 6.0 AND debtRatio ≤ 0.45 AND savingsRate < 0.20',
          exitDescription: 'EF ≥ 9mo, debtRatio ≤ 0.30, savingsRate ≥ 0.18',
          evolutionDescription: 'Graduates to BusinessOwnerOptimize',
        ),
      );

  DecisionPolicy _businessOwnerOptimize(LifecycleStage stage) => DecisionPolicy(
        id: 'business_owner_optimize_v1',
        name: 'Business Owner — Optimise',
        archetype: UserArchetype.businessOwner,
        lifecycleStage: stage,
        priority: 30,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.18,
          liquidity: 0.15,
          goalImpact: 0.15,
          behavior: 0.10,
          taxes: 0.22,
          opportunityCost: 0.20,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 9.0,
          minSavingsRate: 0.20,
          safeDebtRatio: 0.30,
          criticalDebtRatio: 0.45,
          taxEfficiencyTarget: 0.90,
          minOpportunityCostRate: 0.20,
          behaviorMinimumConsistency: 0.50,
        ),
        evolutionRules: const [],
        selectionReason:
            'Business Owner Optimise: GST, presumptive tax, dividends — highest tax weight of all policies',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription:
              'Business owner with 9+ months EF, controlled debt, 18%+ savings rate',
          activationDescription:
              'emergencyFundMonths ≥ 9.0 AND debtRatio ≤ 0.30 AND savingsRate ≥ 0.20',
          exitDescription: 'No standard exit — apex policy for business owner archetype',
          evolutionDescription: 'May graduate to PreRetirement on age trigger',
        ),
      );

  // ── Lifecycle-override policies ───────────────────────────────────────────

  DecisionPolicy _preRetirementPolicy(LifecycleStage stage) => DecisionPolicy(
        id: 'pre_retirement_v1',
        name: 'Pre-Retirement',
        archetype: UserArchetype.preRetiree,
        lifecycleStage: LifecycleStage.preRetirement,
        priority: 90,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.20,
          liquidity: 0.28,
          goalImpact: 0.22,
          behavior: 0.10,
          taxes: 0.12,
          opportunityCost: 0.08,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 12.0,
          minSavingsRate: 0.25,
          safeDebtRatio: 0.30,
          criticalDebtRatio: 0.40,
          taxEfficiencyTarget: 0.85,
          minOpportunityCostRate: 0.15,
          behaviorMinimumConsistency: 0.50,
        ),
        evolutionRules: [
          const PolicyEvolutionRule(
            triggerId: 'pre_retirement_to_retired',
            description: 'Retirement age reached with sufficient liquidity buffer',
            fromPolicyId: 'pre_retirement_v1',
            toPolicyId: 'retired_v1',
            conditions: [
              PolicyCondition(
                factKey: 'ageYears',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 60,
              ),
              PolicyCondition(
                factKey: 'emergencyFundMonths',
                operator: ConditionOp.greaterThanOrEqual,
                threshold: 12,
              ),
            ],
            evaluationMode: EvolutionEvalMode.allConditions,
            graduationLabel:
                'Welcome to your retirement phase. Your financial strategy now focuses on sustainable income and capital preservation.',
          ),
        ],
        selectionReason:
            'Pre-Retirement lifecycle override: de-risking and retirement buffer building',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Age 55–59 or within 5 years of planned retirement',
          activationDescription: 'LifecycleStage.preRetirement (age ≥ 55) OR archetype=preRetiree',
          exitDescription: 'age ≥ 60 AND emergencyFundMonths ≥ 12',
          evolutionDescription: 'Graduates to RetiredPolicy',
        ),
      );

  DecisionPolicy _retiredPolicy(LifecycleStage stage) => DecisionPolicy(
        id: 'retired_v1',
        name: 'Retired',
        archetype: UserArchetype.retiree,
        lifecycleStage: LifecycleStage.retirement,
        priority: 100,
        weights: AxisWeightProfile.validated(
          cashFlow: 0.25,
          liquidity: 0.32,
          goalImpact: 0.18,
          behavior: 0.13,
          taxes: 0.08,
          opportunityCost: 0.04,
        ),
        thresholds: const PolicyThresholds(
          emergencyFundTargetMonths: 24.0,
          minSavingsRate: 0.0,
          safeDebtRatio: 0.20,
          criticalDebtRatio: 0.30,
          taxEfficiencyTarget: 0.70,
          minOpportunityCostRate: 0.02,
          behaviorMinimumConsistency: 0.50,
        ),
        evolutionRules: const [],
        selectionReason:
            'Retirement lifecycle override: capital preservation and sustainable withdrawal',
        schemaVersion: _kSchema,
        effectiveAt: DateTime.now(),
        activationCriteria: const PolicyActivationCriteria(
          eligibilityDescription: 'Age 60+ or explicitly in retirement/distribution phase',
          activationDescription: 'LifecycleStage.retirement (age ≥ 60) OR archetype=retiree',
          exitDescription: 'No exit — terminal policy',
          evolutionDescription:
              'No further graduation. Terminal policy for distribution phase.',
        ),
      );

  // ─── Helpers ──────────────────────────────────────────────────────────────

  PolicyDecision _makeDecision({
    required DecisionPolicy policy,
    required List<String> matchedConditions,
    required double confidence,
    required String reason,
  }) {
    return PolicyDecision(
      policy: policy,
      policyId: policy.id,
      policyLabel: policy.name,
      reason: reason,
      matchedConditions: matchedConditions,
      confidence: confidence,
      fallbackUsed: false,
    );
  }

  PolicyDecision _fallback(LifecycleStage stage) {
    final policy = _salariedBuild(stage);
    return PolicyDecision(
      policy: policy,
      policyId: policy.id,
      policyLabel: policy.name,
      reason: 'Insufficient data to determine precise policy. '
          'Applying conservative SalariedBuild default.',
      matchedConditions: ['fallback: insufficient archetype/fact data'],
      confidence: 0.50,
      fallbackUsed: true,
    );
  }

  String _salariedReason(
      String id, double ef, double debt, double savings) =>
      'Salaried archetype: EF=${ef.toStringAsFixed(1)}mo, '
      'debt=${debt.toStringAsFixed(2)}, savings=${savings.toStringAsFixed(2)} '
      '→ policy=$id';

  String _freelancerReason(String id, double ef, double debt) =>
      'Freelancer archetype: income volatility is the meta-problem. '
      'EF=${ef.toStringAsFixed(1)}mo, debt=${debt.toStringAsFixed(2)} → policy=$id';

  String _businessOwnerReason(String id, double ef, double debt) =>
      'Business Owner archetype: personal-business separation critical. '
      'EF=${ef.toStringAsFixed(1)}mo, debt=${debt.toStringAsFixed(2)} → policy=$id';
}

// Internal selection candidate — used for priority-based resolution.
class _Candidate {
  const _Candidate({
    required this.policy,
    required this.matchedConditions,
    required this.confidence,
    required this.reason,
  });
  final DecisionPolicy policy;
  final List<String> matchedConditions;
  final double confidence;
  final String reason;
}
