import 'package:flutter/foundation.dart';

/// Persisted record of the current active policy and transition history for a user.
///
/// Written by [PolicyEvolutionEngine] when a policy transition occurs.
/// Read by [PolicySelector] to seed the selection with current context.
///
/// This record powers the user-facing policy progression narrative:
/// "You've progressed from Survive → Build Wealth."
@immutable
class PolicyStateRecord {
  const PolicyStateRecord({
    required this.userId,
    required this.activePolicyId,
    required this.activatedAt,
    this.previousPolicyId,
    this.graduatedAt,
    this.graduationReason,
    this.triggerRuleId,
    this.overrideActive = false,
    this.overrideReason,
  });

  final String userId;

  /// The currently active policy ID (e.g. 'salaried_build_v1').
  final String activePolicyId;

  /// When the current policy became active.
  final DateTime activatedAt;

  /// The policy that was active before the last transition, if any.
  final String? previousPolicyId;

  /// When the user last graduated to a new policy.
  final DateTime? graduatedAt;

  /// User-facing message that was shown at graduation time.
  final String? graduationReason;

  /// The [PolicyEvolutionRule.triggerId] that caused the last transition.
  final String? triggerRuleId;

  /// True when the user has manually overridden the inferred policy.
  /// Manual overrides are constrained — users cannot override protective rules.
  final bool overrideActive;

  final String? overrideReason;

  /// Duration this policy has been active.
  Duration get activeDuration => DateTime.now().difference(activatedAt);

  /// True if this record shows a policy progression (not the first ever policy).
  bool get hasProgressed => previousPolicyId != null && graduatedAt != null;

  PolicyStateRecord copyWith({
    String? activePolicyId,
    DateTime? activatedAt,
    String? previousPolicyId,
    DateTime? graduatedAt,
    String? graduationReason,
    String? triggerRuleId,
    bool? overrideActive,
    String? overrideReason,
  }) {
    return PolicyStateRecord(
      userId: userId,
      activePolicyId: activePolicyId ?? this.activePolicyId,
      activatedAt: activatedAt ?? this.activatedAt,
      previousPolicyId: previousPolicyId ?? this.previousPolicyId,
      graduatedAt: graduatedAt ?? this.graduatedAt,
      graduationReason: graduationReason ?? this.graduationReason,
      triggerRuleId: triggerRuleId ?? this.triggerRuleId,
      overrideActive: overrideActive ?? this.overrideActive,
      overrideReason: overrideReason ?? this.overrideReason,
    );
  }
}

/// Repository contract for [PolicyStateRecord] persistence.
abstract class PolicyStateRepository {
  String get engineVersion;

  /// Retrieve the current state record for a user. Returns null when the user
  /// has no stored policy history — first-time policy selection.
  Future<PolicyStateRecord?> getForUser(String userId);

  /// Persist a new or updated policy state record.
  Future<void> save(PolicyStateRecord record);
}
