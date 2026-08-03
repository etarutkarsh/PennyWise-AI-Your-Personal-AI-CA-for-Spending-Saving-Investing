// Defines the EvidenceBuilder cross-cutting domain service.

import '../decision/decision_type.dart';
import '../decision/explanation.dart';
import '../partner/matching_context.dart';
import '../value_objects/ids.dart';

/// Assembles structured evidence for a Decision recommendation.
///
/// The Evidence Builder never computes — it assembles. Each source context
/// (Finance, Behavioral, Knowledge Graph, Goals) is the authority on its
/// own data. This service queries all of them and returns structured
/// [EvidenceItem]s that feed both the [Explanation] and [Confidence] score.
///
/// Design rule: the number, recency, and source diversity of [EvidenceItem]s
/// directly feeds [Confidence.score]. Missing data → honest limitations
/// surfaced in [Explanation.limitations], never silent gaps.
///
/// Today: [StubEvidenceBuilder] returns minimal evidence from [MatchingContext].
/// Phase 6: [GraphBackedEvidenceBuilder] queries the PostgreSQL knowledge graph.
abstract class EvidenceBuilder {
  /// Build evidence items for the given decision context.
  ///
  /// [userId] — the user for whom evidence is assembled.
  /// [decisionType] — filters which evidence sources are most relevant.
  /// [context] — the [MatchingContext] already assembled by the calling engine,
  ///   used as a lightweight evidence source before the full graph is available.
  Future<List<EvidenceItem>> buildFor({
    required UserId userId,
    required DecisionType decisionType,
    required MatchingContext context,
  });

  /// Returns limitations describing what evidence is missing.
  ///
  /// Every missing source degrades [Confidence.score].
  /// These limitations surface in [Explanation.limitations].
  List<String> missingDataLimitations(MatchingContext context);
}
