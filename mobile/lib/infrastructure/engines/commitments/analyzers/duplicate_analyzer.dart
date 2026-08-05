import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/duplicate_analysis.dart';
import '../../../../domain/shared/analyzer_result.dart';

class DuplicateAnalyzer {
  const DuplicateAnalyzer();

  static const Map<String, List<String>> _groups = {
    'Video Streaming': [
      'Netflix',
      'Amazon Prime',
      'Disney+ Hotstar',
      'ZEE5',
      'JioCinema',
      'SonyLIV',
      'YouTube Premium'
    ],
    'AI Assistants': ['Claude (Anthropic)', 'ChatGPT', 'Google Gemini'],
    'Cloud Storage': ['Google One', 'iCloud+', 'Dropbox'],
    'Design Tools': ['Adobe Creative', 'Canva', 'Figma'],
    'Music Streaming': ['Spotify', 'YouTube Premium', 'Amazon Prime'],
  };

  static const Map<String, String> _consolidationSuggestions = {
    'Video Streaming':
        'Pick your most-watched platform. A family plan can cut per-person cost by 40-60%.',
    'AI Assistants':
        'Most AI assistants have overlapping capabilities. One subscription is usually sufficient.',
    'Cloud Storage':
        'Consolidating to one storage service and buying more storage is almost always cheaper.',
    'Design Tools':
        'Consider which tool you use most frequently and cancel the rest.',
    'Music Streaming':
        'One music service covers most libraries. Check if your existing subscription already includes music.',
  };

  AnalyzerResult<DuplicateAnalysis> analyze(
    List<DetectedCommitment> subscriptions,
  ) {
    final startedAt = DateTime.now();
    final duplicateGroups = <DuplicateGroup>[];

    for (final entry in _groups.entries) {
      final matched = subscriptions
          .where((c) => entry.value.contains(c.displayName))
          .toList();

      if (matched.length >= 2) {
        final totalMonthly =
            matched.fold<double>(0, (s, c) => s + c.monthlyEquivalent);
        final annualTotal = totalMonthly * 12;
        final insight =
            'You have ${matched.length} ${entry.key.toLowerCase()} services '
            'costing ₹${totalMonthly.round()}/month. '
            'A shared or single plan could reduce this significantly.';

        duplicateGroups.add(DuplicateGroup(
          category: entry.key,
          serviceNames: matched.map((c) => c.displayName).toList(),
          totalMonthly: totalMonthly,
          annualTotal: annualTotal,
          insight: insight,
          consolidationSuggestion:
              _consolidationSuggestions[entry.key] ?? 'Consider consolidating.',
        ));
      }
    }

    final totalMonthlyWaste =
        duplicateGroups.fold<double>(0, (s, g) => s + g.totalMonthly);
    final totalAnnualWaste = totalMonthlyWaste * 12;
    final consolidationSuggestions =
        duplicateGroups.map((g) => g.consolidationSuggestion).toList();

    final analysis = DuplicateAnalysis(
      groups: duplicateGroups,
      totalMonthlyWaste: totalMonthlyWaste,
      totalAnnualWaste: totalAnnualWaste,
      consolidationSuggestions: consolidationSuggestions,
    );

    return AnalyzerResult.of(
      analyzerId: 'duplicate_analyzer',
      result: analysis,
      confidence: 0.90,
      startedAt: startedAt,
    );
  }
}
