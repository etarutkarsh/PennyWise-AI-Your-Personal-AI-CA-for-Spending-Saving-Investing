/// Canonical classification of how a financial transaction was settled.
/// More granular than `paymentMethod` on TransactionEntity — this
/// distinguishes between voluntary UPI and UPI AutoPay (mandate-based),
/// and between NACH pull and standing instructions.
enum PaymentRail {
  /// UPI push payment (PhonePe, GPay, Paytm, BHIM).
  upi,

  /// UPI AutoPay mandate — recurring, pulled automatically.
  upiAutopay,

  /// NACH (National Automated Clearing House) debit mandate — used by insurance/SIPs.
  nach,

  /// ECS (Electronic Clearing Service) — legacy recurring debit (pre-NACH).
  ecs,

  /// Standing Instruction — bank-to-bank fixed recurring transfer.
  standingInstruction,

  /// IMPS (Immediate Payment Service) — real-time interbank.
  imps,

  /// NEFT (National Electronic Funds Transfer) — batch interbank.
  neft,

  /// RTGS (Real Time Gross Settlement) — large-value real-time.
  rtgs,

  /// Debit/credit card swipe at POS terminal.
  cardSwipe,

  /// Card payment online (e-commerce, subscriptions).
  cardOnline,

  /// ATM cash withdrawal.
  atm,

  /// Digital wallet (Paytm Wallet, Mobikwik, etc.).
  wallet,

  /// Cash — manually entered, no electronic trail.
  cash,

  /// Source is known but rail is unresolvable.
  unknown,
}

extension PaymentRailExtension on PaymentRail {
  String get label {
    switch (this) {
      case PaymentRail.upi:          return 'UPI';
      case PaymentRail.upiAutopay:   return 'UPI AutoPay';
      case PaymentRail.nach:         return 'NACH';
      case PaymentRail.ecs:          return 'ECS';
      case PaymentRail.standingInstruction: return 'Standing Instruction';
      case PaymentRail.imps:         return 'IMPS';
      case PaymentRail.neft:         return 'NEFT';
      case PaymentRail.rtgs:         return 'RTGS';
      case PaymentRail.cardSwipe:    return 'Card (POS)';
      case PaymentRail.cardOnline:   return 'Card (Online)';
      case PaymentRail.atm:          return 'ATM';
      case PaymentRail.wallet:       return 'Wallet';
      case PaymentRail.cash:         return 'Cash';
      case PaymentRail.unknown:      return 'Unknown';
    }
  }

  /// True for rails that indicate a recurring mandate — key input for CommitmentEngine.
  bool get isMandate =>
      this == PaymentRail.nach ||
      this == PaymentRail.ecs ||
      this == PaymentRail.upiAutopay ||
      this == PaymentRail.standingInstruction;

  /// True for rails where confidence should be treated as bank-verified.
  bool get isInstitutionalRail =>
      this == PaymentRail.nach ||
      this == PaymentRail.ecs ||
      this == PaymentRail.neft ||
      this == PaymentRail.rtgs ||
      this == PaymentRail.imps;
}
