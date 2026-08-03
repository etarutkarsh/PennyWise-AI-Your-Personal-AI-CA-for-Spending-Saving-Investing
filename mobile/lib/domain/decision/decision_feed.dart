// Defines DecisionFeed and DecisionFeedItem — the daily opportunity feed shown on the home screen.

import 'package:flutter/foundation.dart';
import 'decision.dart';

/// The type of card shown in the Decision Feed.
enum DecisionFeedItemType {
  action,     // Today's Best Decision card
  program,    // Partner program card
  insight,    // Behavioral observation
  warning,    // Risk alert
  learning,   // Contextual education card
  event,      // Life event detected
  review,     // After-Action Review (AAR) card
  journal,    // Decision history entry
}

/// A single item in the daily Decision Feed.
@immutable
class DecisionFeedItem {
  final String id;
  final DecisionFeedItemType type;

  /// Lower number = higher priority in the feed.
  final int priority;

  final Decision? linkedDecision;
  final bool requiresAction;
  final DateTime generatedAt;

  /// Typed payload for the rendering layer. Schema varies by [type].
  final Map<String, dynamic> payload;

  const DecisionFeedItem({
    required this.id,
    required this.type,
    required this.priority,
    this.linkedDecision,
    required this.requiresAction,
    required this.generatedAt,
    required this.payload,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DecisionFeedItem && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DecisionFeedItem(id: $id, type: $type, priority: $priority, '
      'requiresAction: $requiresAction)';
}

/// The full daily Decision Feed for a user.
@immutable
class DecisionFeed {
  final List<DecisionFeedItem> items;
  final DateTime generatedAt;

  const DecisionFeed({
    required this.items,
    required this.generatedAt,
  });

  bool get isEmpty => items.isEmpty;

  int get actionCount => items.where((i) => i.requiresAction).length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DecisionFeed && other.generatedAt == generatedAt);

  @override
  int get hashCode => generatedAt.hashCode;

  @override
  String toString() =>
      'DecisionFeed(items: ${items.length}, actions: $actionCount, at: $generatedAt)';
}
