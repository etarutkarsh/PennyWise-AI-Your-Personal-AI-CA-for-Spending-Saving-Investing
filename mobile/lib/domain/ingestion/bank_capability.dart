import 'package:flutter/foundation.dart';

/// The set of SMS alert types a bank is known to generate.
///
/// Used by [BankCapability] to answer "can this bank's SMS contain a SIP deduction?"
/// before we even attempt to parse — reducing false-positive extraction attempts.
enum BankSmsCapability {
  /// Basic debit notifications.
  debitAlert,

  /// Basic credit notifications.
  creditAlert,

  /// UPI payments sent.
  upiDebit,

  /// UPI payments received.
  upiCredit,

  /// POS card transactions.
  cardSwipe,

  /// Online card transactions.
  cardOnline,

  /// ATM cash withdrawals.
  atmWithdrawal,

  /// NACH mandate debits.
  nachDebit,

  /// ECS mandate debits.
  ecsDebit,

  /// UPI AutoPay recurring charges.
  upiAutopay,

  /// Available balance included in the SMS body.
  availableBalance,

  /// Salary / payroll credit alerts.
  salaryCredit,

  /// Loan EMI deduction alerts.
  loanEmi,

  /// Mutual fund SIP deduction alerts.
  sipDeduction,

  /// FD / savings interest credit alerts.
  interestCredit,

  /// FD maturity alerts.
  fdMaturity,

  /// Transaction reversal / refund credit alerts.
  reversalCredit,
}

/// Describes what SMS capabilities a specific bank supports, together with
/// its TRAI sender ID prefixes used for routing.
///
/// Predefined instances are available as static constants on this class:
/// [BankCapability.hdfc], [BankCapability.sbi], [BankCapability.icici],
/// [BankCapability.axis], [BankCapability.kotak].
@immutable
class BankCapability {
  const BankCapability({
    required this.bankId,
    required this.displayName,
    required this.capabilities,
    this.senderPrefixes = const [],
    this.note,
  });

  /// Short identifier, e.g. 'hdfc', 'sbi', 'icici', 'axis', 'kotak'.
  final String bankId;

  final String displayName;

  /// The alert types this bank sends via SMS.
  final Set<BankSmsCapability> capabilities;

  /// TRAI sender ID prefixes, e.g. ['HDFCBK', 'HDFCBN', 'HDFC'].
  final List<String> senderPrefixes;

  /// Optional caveat about SMS delivery behaviour for this bank.
  final String? note;

  bool supports(BankSmsCapability cap) => capabilities.contains(cap);
  bool get supportsBalance => supports(BankSmsCapability.availableBalance);
  bool get supportsMandates =>
      supports(BankSmsCapability.nachDebit) ||
      supports(BankSmsCapability.ecsDebit) ||
      supports(BankSmsCapability.upiAutopay);

  // ── Predefined bank profiles ───────────────────────────────────────────────

  static const BankCapability hdfc = BankCapability(
    bankId: 'hdfc',
    displayName: 'HDFC Bank',
    senderPrefixes: ['HDFCBK', 'HDFCBN', 'HDFC'],
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.cardOnline,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.upiAutopay,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
      BankSmsCapability.sipDeduction,
      BankSmsCapability.reversalCredit,
    },
    note: 'UPI < ₹100 sent / < ₹500 received may not generate SMS (June 2024)',
  );

  static const BankCapability sbi = BankCapability(
    bankId: 'sbi',
    displayName: 'State Bank of India',
    senderPrefixes: ['SBIBNK', 'SBICRD', 'SBI', 'SBIPSG'],
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.cardOnline,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.upiAutopay,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
      BankSmsCapability.reversalCredit,
    },
  );

  static const BankCapability icici = BankCapability(
    bankId: 'icici',
    displayName: 'ICICI Bank',
    senderPrefixes: ['ICICIB', 'ICICI', 'ICICIBK'],
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.cardOnline,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.upiAutopay,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
      BankSmsCapability.sipDeduction,
      BankSmsCapability.reversalCredit,
    },
  );

  static const BankCapability axis = BankCapability(
    bankId: 'axis',
    displayName: 'Axis Bank',
    senderPrefixes: ['AXISBK', 'AXIS', 'AXISBN'],
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.cardOnline,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.upiAutopay,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
      BankSmsCapability.reversalCredit,
    },
  );

  static const BankCapability kotak = BankCapability(
    bankId: 'kotak',
    displayName: 'Kotak Mahindra Bank',
    senderPrefixes: ['KOTAKB', 'KOTAK', 'KTKMBL'],
    capabilities: {
      BankSmsCapability.debitAlert,
      BankSmsCapability.creditAlert,
      BankSmsCapability.upiDebit,
      BankSmsCapability.upiCredit,
      BankSmsCapability.cardSwipe,
      BankSmsCapability.atmWithdrawal,
      BankSmsCapability.nachDebit,
      BankSmsCapability.ecsDebit,
      BankSmsCapability.availableBalance,
      BankSmsCapability.salaryCredit,
      BankSmsCapability.loanEmi,
    },
    note: 'Kotak charges ₹25/month after free SMS limit exceeded',
  );

  /// All predefined bank capability profiles.
  static const List<BankCapability> all = [hdfc, sbi, icici, axis, kotak];
}
