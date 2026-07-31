import '../../core/services/network/api_client.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';

class TransactionRepository {
  TransactionRepository(this._client);

  final ApiClient _client;

  Future<List<TransactionEntity>> getAll() async {
    final res = await _client.dio.get('/transactions');
    return (res.data as List)
        .map((j) => TransactionEntity.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionEntity> create({
    required double amount,
    required String merchant,
    required String direction,
    String? categoryId,
    String? note,
    String? paymentMethod,
    DateTime? transactionDate,
    // Tax-ready fields
    String? taxCategory,
    String? receiptUrl,
    bool businessExpense = false,
  }) async {
    final res = await _client.dio.post('/transactions', data: {
      'amount': amount,
      'merchant': merchant,
      'direction': direction,
      'source': 'MANUAL',
      'transactionDate': (transactionDate ?? DateTime.now()).toUtc().toIso8601String(),
      if (categoryId != null) 'categoryId': categoryId,
      if (note != null && note.isNotEmpty) 'note': note,
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (taxCategory != null) 'taxCategory': taxCategory,
      if (receiptUrl != null) 'receiptUrl': receiptUrl,
      if (businessExpense) 'businessExpense': true,
    });
    return TransactionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/transactions/$id');
  }
}
