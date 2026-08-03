import '../../domain/engines/event_replay_engine.dart';
import '../../domain/ingestion/extraction_result.dart';
import '../../domain/ingestion/parser_versions.dart';

/// Stub implementation of EventReplayEngine.
///
/// Returns empty replay results — no-op for Phase 8.1/8.2 scaffolding.
/// Phase 8.2 upgrade: replace with SmsEventReplayEngine that calls
/// SmsParserService.parse() and feeds results into TransactionNormalizer.
class StubEventReplayEngine implements EventReplayEngine {
  const StubEventReplayEngine();

  static const _kVersion = 'event-replay-stub-v1';

  @override
  String get engineVersion => _kVersion;

  @override
  Future<EventReplayResult> replay(EventReplayParams params) async {
    final eligible = eligibleEventIds(
      params.rawEvents,
      fromParserVersion: params.fromParserVersion,
      toParserVersion: params.toParserVersion,
    );

    return EventReplayResult(
      totalEvents: params.rawEvents.length,
      eligibleForReplay: eligible.length,
      successCount: 0,
      failedCount: 0,
      skippedCount: params.rawEvents.length,
      updatedCanonical: const [],
      dryRun: true,
    );
  }

  @override
  ExtractionResult reparse(String rawText, {required String targetParserVersion}) {
    // Stub: return a rejected result — no parser wired yet
    return (ExtractionResultBuilder(
      parserVersion: targetParserVersion,
      rawText: rawText,
    )..reject('StubEventReplayEngine: no parser wired'))
        .build();
  }

  @override
  List<String> eligibleEventIds(
    List<Map<String, dynamic>> rawEvents, {
    required String fromParserVersion,
    required String toParserVersion,
  }) =>
      rawEvents
          .where((e) {
            final version = (e['originalParserVersion'] as String?) ?? kLegacyParserVersion;
            return isOlderThan(version, toParserVersion);
          })
          .map((e) => e['id'] as String)
          .toList();
}
