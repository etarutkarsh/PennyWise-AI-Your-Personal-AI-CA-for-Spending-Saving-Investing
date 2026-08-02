import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// DecisionOutcome
// ---------------------------------------------------------------------------

class DecisionOutcome {
  const DecisionOutcome({
    this.followedRecommendation,
    this.accuracyScore,
    this.lessons,
  });

  final bool? followedRecommendation;
  final double? accuracyScore;
  final List<String>? lessons;

  factory DecisionOutcome.fromJson(Map<String, dynamic> json) {
    return DecisionOutcome(
      followedRecommendation: json['followedRecommendation'] as bool?,
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
      lessons: (json['lessons'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// DecisionMemoryEntry  (used for both timeline and full memory endpoints)
// ---------------------------------------------------------------------------

class DecisionMemoryEntry {
  const DecisionMemoryEntry({
    required this.id,
    required this.itemName,
    required this.itemPrice,
    required this.recommendation,
    required this.recommendationStrength,
    required this.reviewAfter,
    required this.status,
    required this.createdAt,
    this.decisionType,
    this.followedRecommendation,
    this.accuracyScore,
    this.outcome,
  });

  final String id;
  final String itemName;
  final double itemPrice;
  final String recommendation;       // SAFE_TO_BUY | WAIT_AND_SAVE | DONT_BUY
  final String recommendationStrength; // HIGH | MEDIUM | LOW
  final String reviewAfter;          // YYYY-MM-DD
  final String status;               // PENDING_REVIEW | REVIEWED
  final String createdAt;            // ISO-8601
  final String? decisionType;

  // Flat fields from TimelineEntryDto (null when not reviewed)
  final bool? followedRecommendation;
  final double? accuracyScore;

  // Nested outcome from DecisionMemoryDto
  final DecisionOutcome? outcome;

  // ── Convenience getters ──────────────────────────────────────────────────

  bool get isReviewed => status == 'REVIEWED';
  bool get isPending => status == 'PENDING_REVIEW';

  String get formattedPrice {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return fmt.format(itemPrice);
  }

  String get formattedDate {
    try {
      final dt = DateTime.parse(createdAt);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return createdAt;
    }
  }

  String get reviewAfterFormatted {
    try {
      final dt = DateTime.parse(reviewAfter);
      return DateFormat('d MMM yyyy').format(dt);
    } catch (_) {
      return reviewAfter;
    }
  }

  String get verdictLabel {
    switch (recommendation) {
      case 'SAFE_TO_BUY':
        return 'Go Ahead';
      case 'WAIT_AND_SAVE':
        return 'Wait & Save';
      case 'DONT_BUY':
        return "Don't Buy";
      default:
        return recommendation;
    }
  }

  /// Returns a [Color] corresponding to the recommendation.
  Color get verdictColor {
    switch (recommendation) {
      case 'SAFE_TO_BUY':
        return const Color(0xFF22C55E);   // success green
      case 'WAIT_AND_SAVE':
        return const Color(0xFFFFB830);   // amber
      case 'DONT_BUY':
        return const Color(0xFFEF4444);   // danger red
      default:
        return const Color(0xFF8A8FA8);   // muted
    }
  }

  /// Effective followedRecommendation (checks both flat field and nested outcome).
  bool? get effectiveFollowed =>
      followedRecommendation ?? outcome?.followedRecommendation;

  /// Effective accuracy score (checks both flat field and nested outcome).
  double? get effectiveAccuracy =>
      accuracyScore ?? outcome?.accuracyScore;

  int get createdYear {
    try {
      return DateTime.parse(createdAt).year;
    } catch (_) {
      return 0;
    }
  }

  // ── Factories ─────────────────────────────────────────────────────────────

  /// Parses a TimelineEntryDto (flat structure from GET /decision-memory/timeline).
  factory DecisionMemoryEntry.fromTimelineJson(Map<String, dynamic> json) {
    return DecisionMemoryEntry(
      id: json['id'] as String,
      itemName: json['itemName'] as String,
      itemPrice: (json['itemPrice'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
      recommendationStrength: json['recommendationStrength'] as String,
      reviewAfter: json['reviewAfter'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      followedRecommendation: json['followedRecommendation'] as bool?,
      accuracyScore: (json['accuracyScore'] as num?)?.toDouble(),
    );
  }

  /// Parses a DecisionMemoryDto (nested outcome from GET /decision-memory).
  factory DecisionMemoryEntry.fromJson(Map<String, dynamic> json) {
    DecisionOutcome? outcome;
    if (json['outcome'] != null) {
      outcome = DecisionOutcome.fromJson(
        json['outcome'] as Map<String, dynamic>,
      );
    }
    return DecisionMemoryEntry(
      id: json['id'] as String,
      decisionType: json['decisionType'] as String?,
      itemName: json['itemName'] as String,
      itemPrice: (json['itemPrice'] as num).toDouble(),
      recommendation: json['recommendation'] as String,
      recommendationStrength: json['recommendationStrength'] as String,
      reviewAfter: json['reviewAfter'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      outcome: outcome,
    );
  }
}

// ---------------------------------------------------------------------------
// DecisionInsights  (GET /decision-memory/insights)
// ---------------------------------------------------------------------------

class DecisionInsights {
  const DecisionInsights({
    required this.totalDecisions,
    required this.reviewedDecisions,
    required this.followRate,
    this.averageAccuracy,
    required this.pendingReviews,
    required this.observations,
  });

  final int totalDecisions;
  final int reviewedDecisions;
  final double followRate;         // 0.0–1.0
  final double? averageAccuracy;
  final int pendingReviews;
  final List<String> observations;

  factory DecisionInsights.fromJson(Map<String, dynamic> json) {
    return DecisionInsights(
      totalDecisions: json['totalDecisions'] as int,
      reviewedDecisions: json['reviewedDecisions'] as int,
      followRate: (json['followRate'] as num).toDouble(),
      averageAccuracy: (json['averageAccuracy'] as num?)?.toDouble(),
      pendingReviews: json['pendingReviews'] as int,
      observations: (json['observations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );
  }

  String get followRateLabel =>
      '${(followRate * 100).round()}% followed';

  String get accuracyLabel => averageAccuracy != null
      ? '${(averageAccuracy! * 100).round()}% accurate'
      : '–';
}
