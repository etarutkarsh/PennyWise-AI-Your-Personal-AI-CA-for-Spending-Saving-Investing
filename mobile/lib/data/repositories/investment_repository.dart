import '../../core/constants/api_constants.dart';
import '../../core/services/network/api_client.dart';
import '../models/investment_model.dart';

class InvestmentRepository {
  const InvestmentRepository(this._api);
  final ApiClient _api;

  Future<List<InvestmentModel>> getAll() async {
    final res = await _api.dio.get(ApiConstants.investments);
    return (res.data as List)
        .map((j) => InvestmentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<InvestmentModel> create({
    required String instrumentType,
    required String name,
    required double investedAmount,
    double? currentValue,
    double? units,
    DateTime? startedOn,
  }) async {
    final res = await _api.dio.post(ApiConstants.investments, data: {
      'instrumentType': instrumentType,
      'name': name,
      'investedAmount': investedAmount,
      if (currentValue != null) 'currentValue': currentValue,
      if (units != null) 'units': units,
      if (startedOn != null)
        'startedOn': startedOn.toIso8601String().split('T')[0],
    });
    return InvestmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<InvestmentModel> updateCurrentValue(
      String id, double currentValue) async {
    final res = await _api.dio.patch(
      '${ApiConstants.investments}/$id/current-value',
      data: {'currentValue': currentValue},
    );
    return InvestmentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _api.dio.delete('${ApiConstants.investments}/$id');
  }
}
