/// Mirrors com.pennywise.dto.TransactionDto on the backend.
class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.amount,
    required this.merchant,
    required this.categoryName,
    required this.transactionDate,
    required this.direction,
    required this.source,
    this.categoryId,
    this.note,
    this.paymentMethod,
    this.recurring = false,
    // Tax-ready fields (Phase 3/4)
    this.receiptUrl,
    this.taxCategory,
    this.verificationStatus = 'UNVERIFIED',
    this.businessExpense = false,
  });

  final String id;
  final double amount;
  final String merchant;
  final String categoryName;
  final DateTime transactionDate;
  final String direction;         // DEBIT | CREDIT
  final String source;            // SMS | BANK_NOTIFICATION | MANUAL | EMAIL | OCR
  final String? categoryId;
  final String? note;
  final String? paymentMethod;    // UPI | CARD | CASH | NETBANKING | WALLET
  final bool recurring;

  // Tax-ready fields
  final String? receiptUrl;
  final String? taxCategory;      // 80C | 80D | HRA | BUSINESS_EXPENSE | CAPITAL_GAINS | etc.
  final String verificationStatus; // UNVERIFIED | VERIFIED | DISPUTED
  final bool businessExpense;

  factory TransactionEntity.fromJson(Map<String, dynamic> json) => TransactionEntity(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        merchant: json['merchant'] as String? ?? 'Unknown',
        categoryName: json['categoryName'] as String? ?? 'Uncategorized',
        transactionDate: DateTime.parse(json['transactionDate'] as String),
        direction: json['direction'] as String,
        source: json['source'] as String? ?? 'MANUAL',
        categoryId: json['categoryId'] as String?,
        note: json['note'] as String?,
        paymentMethod: json['paymentMethod'] as String?,
        recurring: json['recurring'] as bool? ?? false,
        receiptUrl: json['receiptUrl'] as String?,
        taxCategory: json['taxCategory'] as String?,
        verificationStatus: json['verificationStatus'] as String? ?? 'UNVERIFIED',
        businessExpense: json['businessExpense'] as bool? ?? false,
      );
}
