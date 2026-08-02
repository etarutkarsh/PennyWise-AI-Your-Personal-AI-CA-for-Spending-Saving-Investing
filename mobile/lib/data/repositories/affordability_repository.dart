import '../../core/services/network/api_client.dart';
import '../../features/calculator/domain/entities/affordability_result.dart';

class AffordabilityRepository {
  AffordabilityRepository(this._client);

  final ApiClient _client;

  Future<AffordabilityResult> check({
    required String itemName,
    required double price,
    double? downPayment,
    double? interestRatePercent,
    int? tenureMonths,
    double? existingMonthlyEmi,
  }) async {
    final body = <String, dynamic>{
      'itemName': itemName,
      'price': price,
    };
    if (downPayment != null && downPayment > 0) body['downPayment'] = downPayment;
    if (interestRatePercent != null && interestRatePercent > 0) body['interestRatePercent'] = interestRatePercent;
    if (tenureMonths != null && tenureMonths > 0) body['tenureMonths'] = tenureMonths;
    if (existingMonthlyEmi != null && existingMonthlyEmi > 0) body['existingMonthlyEmi'] = existingMonthlyEmi;

    final res = await _client.dio.post('/affordability/check', data: body);
    return AffordabilityResult.fromJson(res.data as Map<String, dynamic>);
  }
}
