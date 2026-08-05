import '../../../../core/services/commitment_intelligence/commitment_engine.dart';
import '../../../../domain/commitments/commitment_change_delta.dart';

class ChangeDeltaAnalyzer {
  const ChangeDeltaAnalyzer();

  /// Returns null if no previous snapshot available.
  CommitmentChangeDelta? analyze(
    List<DetectedCommitment> current,
    List<String>? previousMerchantKeys,
    Map<String, double>? previousAmounts,
  ) {
    if (previousMerchantKeys == null) return null;

    final currentMap = {
      for (final c in current) c.merchantKey: c,
    };
    final currentKeys = currentMap.keys.toSet();
    final prevKeys = previousMerchantKeys.toSet();

    final newKeys = currentKeys.difference(prevKeys);
    final removedKeys = prevKeys.difference(currentKeys);

    final newCommitmentNames =
        newKeys.map((k) => currentMap[k]?.displayName ?? k).toList();
    final removedCommitmentNames = removedKeys.toList();

    final priceChanges = <CommitmentPriceChange>[];
    if (previousAmounts != null) {
      for (final key in currentKeys.intersection(prevKeys)) {
        final prevAmount = previousAmounts[key];
        final currAmount = currentMap[key]?.avgAmount;
        if (prevAmount != null && currAmount != null && prevAmount > 0) {
          final changePercent =
              ((currAmount - prevAmount) / prevAmount * 100).abs();
          if (changePercent > 5) {
            priceChanges.add(CommitmentPriceChange(
              merchantKey: key,
              displayName: currentMap[key]?.displayName ?? key,
              previousAmount: prevAmount,
              currentAmount: currAmount,
            ));
          }
        }
      }
    }

    // Net monthly change
    final currentTotal =
        current.fold<double>(0, (s, c) => s + c.monthlyEquivalent);
    final previousTotal = previousAmounts != null
        ? previousAmounts.entries
            .where((e) => prevKeys.contains(e.key))
            .fold<double>(0, (s, e) => s + e.value)
        : 0.0;
    final netMonthlyChange = currentTotal - previousTotal;

    return CommitmentChangeDelta(
      newCommitmentNames: newCommitmentNames,
      removedCommitmentNames: removedCommitmentNames,
      priceChanges: priceChanges,
      netMonthlyChange: netMonthlyChange,
      annualChangeImpact: netMonthlyChange * 12,
      detectedAt: DateTime.now(),
    );
  }
}
