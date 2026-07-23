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
  }) async {
    final res = await _client.dio.post('/transactions', data: {
      'amount': amount,
      'merchant': merchant,
      'direction': direction,
      'source': 'MANUAL',
      'transactionDate': DateTime.now().toIso8601String().split('T')[0],
      if (categoryId != null) 'categoryId': categoryId,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return TransactionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/transactions/$id');
  }
}
