// Defines the Currency enum for supported currencies in PennyWise.

/// Supported currencies in the PennyWise platform.
enum Currency {
  inr,
  usd;

  String get symbol => switch (this) {
        Currency.inr => '₹',
        Currency.usd => '\$',
      };

  String get code => switch (this) {
        Currency.inr => 'INR',
        Currency.usd => 'USD',
      };
}
