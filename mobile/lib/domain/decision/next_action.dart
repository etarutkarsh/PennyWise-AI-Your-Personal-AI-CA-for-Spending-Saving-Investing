// Defines NextAction — the UI-level actions available to the user on a Decision card.

import 'package:flutter/foundation.dart';

/// The types of actions a user can take from a Decision card.
enum NextActionType {
  openPartner,
  learn,
  defer,
  accept,
  reject,
  review,
}

/// A single CTA action surfaced on a Decision card in the feed.
@immutable
class NextAction {
  final NextActionType type;
  final String label;

  /// Program ID if type is [NextActionType.openPartner].
  final String? targetProgramId;

  /// Article/lesson ID if type is [NextActionType.learn].
  final String? articleId;

  /// Decision ID if this action is tied to a specific decision.
  final String? decisionId;

  const NextAction({
    required this.type,
    required this.label,
    this.targetProgramId,
    this.articleId,
    this.decisionId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NextAction && other.type == type && other.label == label);

  @override
  int get hashCode => Object.hash(type, label, targetProgramId, decisionId);

  @override
  String toString() => 'NextAction(type: $type, label: "$label")';
}
