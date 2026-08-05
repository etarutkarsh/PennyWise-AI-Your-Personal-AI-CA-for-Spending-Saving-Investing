import '../../../domain/reasoning/decision_axis.dart';
import '../../../domain/reasoning/financial_reasoning_context.dart';

class HistoricalAccuracyAxisAnalyzer {
  const HistoricalAccuracyAxisAnalyzer();

  // Neutral prior: "no history" is not the same as "bad history."
  // We use 0.50 so new users aren't penalized for never having reviewed a recommendation.
  static const double _neutralPrior = 0.50;

  DecisionAxisResult analyze(FinancialReasoningContext ctx) {
    final snapshot = ctx.learningSnapshot;

    if (snapshot == null || snapshot.completedCycles == 0) {
      return const DecisionAxisResult(
        axis: DecisionAxis.historicalAccuracy,
        score: _neutralPrior,
        confidence: 0.0,
        signals: ['No completed recommendation cycles yet'],
        limitation: 'Follow and review recommendations to calibrate historical accuracy',
      );
    }

    // maturity is 0.0–1.0, reflecting how well-calibrated the learning snapshot is.
    // Floor at neutral prior so even low-maturity users (a few cycles) don't
    // drag the compound score below what "no history" would give.
    final score = snapshot.maturity.clamp(_neutralPrior, 1.0);

    final signals = [
      '${snapshot.completedCycles} decision cycle${snapshot.completedCycles == 1 ? '' : 's'} completed',
      'Calibration: ${snapshot.calibrationLabel}',
      if (snapshot.actionableLessons.isNotEmpty)
        '${snapshot.actionableLessons.length} active lesson${snapshot.actionableLessons.length == 1 ? '' : 's'} shaping recommendations',
    ];

    final confidence = snapshot.isCalibrated ? 0.80 : 0.30;

    return DecisionAxisResult(
      axis: DecisionAxis.historicalAccuracy,
      score: score,
      confidence: confidence,
      signals: signals,
    );
  }
}
