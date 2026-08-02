import '../../core/services/network/api_client.dart';
import '../../features/transactions/domain/entities/transaction_entity.dart';

class TransactionRepository {
  TransactionRepository(this._client);

  final ApiClient _client;

  Future<List<TransactionEntity>> getAll({
    String? direction,
    String? category,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (direction != null) params['direction'] = direction;
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    final res = await _client.dio.get(
      '/transactions',
      queryParameters: params.isEmpty ? null : params,
    );
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

  Future<TransactionEntity> update(
    String id, {
    String? merchant,
    String? note,
    double? amount,
    String? categoryId,
    String? paymentMethod,
    bool? recurring,
  }) async {
    final body = <String, dynamic>{};
    if (merchant != null) body['merchant'] = merchant;
    if (note != null) body['note'] = note;
    if (amount != null) body['amount'] = amount;
    if (categoryId != null) body['categoryId'] = categoryId;
    if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
    if (recurring != null) body['recurring'] = recurring;
    final res = await _client.dio.patch('/transactions/$id', data: body);
    return TransactionEntity.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/transactions/$id');
  }
}
