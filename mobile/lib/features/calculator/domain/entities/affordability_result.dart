/// Mirrors com.pennywise.dto.AffordabilityResponse on the backend.
class AffordabilityResult {
  const AffordabilityResult({
    required this.verdict,
    required this.reason,
    this.recommendedWaitMonths,
    this.recommendedMonthlySavings,
    this.expectedPurchaseDate,
    this.investmentSuggestion,
  });

  final String verdict; // SAFE_TO_BUY | WAIT_AND_SAVE | DONT_BUY
  final String reason;
  final int? recommendedWaitMonths;
  final double? recommendedMonthlySavings;
  final DateTime? expectedPurchaseDate;
  final String? investmentSuggestion;

  factory AffordabilityResult.fromJson(Map<String, dynamic> json) => AffordabilityResult(
        verdict: json['verdict'] as String,
        reason: json['reason'] as String,
        recommendedWaitMonths: json['recommendedWaitMonths'] as int?,
        recommendedMonthlySavings: (json['recommendedMonthlySavings'] as num?)?.toDouble(),
        expectedPurchaseDate: json['expectedPurchaseDate'] != null
            ? DateTime.parse(json['expectedPurchaseDate'] as String)
            : null,
        investmentSuggestion: json['investmentSuggestion'] as String?,
      );
}
