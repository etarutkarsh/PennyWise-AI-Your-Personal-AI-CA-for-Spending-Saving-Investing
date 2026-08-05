import 'package:flutter/foundation.dart';

/// Lightweight result wrapper for sub-engine analyzers.
/// Parallel to EngineExecutionResult<T> but for individual analyzers.
@immutable
class AnalyzerResult<T> {
  const AnalyzerResult({
    required this.analyzerId,
    required this.result,
    required this.confidence,
    required this.executedAt,
    required this.executionDuration,
    this.limitations = const [],
    this.evidence = const [],
  });

  final String analyzerId;
  final T result;
  final double confidence;
  final DateTime executedAt;
  final Duration executionDuration;
  final List<String> limitations;
  final List<String> evidence;

  bool get isHighConfidence => confidence >= 0.70;
  bool get isLowConfidence => confidence < 0.40;

  /// Convenience factory for successful result.
  static AnalyzerResult<T> of<T>({
    required String analyzerId,
    required T result,
    required double confidence,
    required DateTime startedAt,
    List<String> limitations = const [],
    List<String> evidence = const [],
  }) =>
      AnalyzerResult<T>(
        analyzerId: analyzerId,
        result: result,
        confidence: confidence,
        executedAt: startedAt,
        executionDuration: DateTime.now().difference(startedAt),
        limitations: limitations,
        evidence: evidence,
      );
}
