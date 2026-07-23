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
  });

  final String id;
  final double amount;
  final String merchant;
  final String categoryName;
  final DateTime transactionDate;
  final String direction; // DEBIT | CREDIT
  final String source; // SMS | BANK_NOTIFICATION | MANUAL | EMAIL | OCR

  factory TransactionEntity.fromJson(Map<String, dynamic> json) => TransactionEntity(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        merchant: json['merchant'] as String? ?? 'Unknown',
        categoryName: json['categoryName'] as String? ?? 'Uncategorized',
        transactionDate: DateTime.parse(json['transactionDate'] as String),
        direction: json['direction'] as String,
        source: json['source'] as String,
      );
}
