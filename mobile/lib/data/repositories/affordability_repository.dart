import '../../core/services/network/api_client.dart';
import '../../features/calculator/domain/entities/affordability_result.dart';

class AffordabilityRepository {
  AffordabilityRepository(this._client);

  final ApiClient _client;

  Future<AffordabilityResult> check(String itemName, double price) async {
    final res = await _client.dio.post('/affordability/check', data: {
      'itemName': itemName,
      'price': price,
    });
    return AffordabilityResult.fromJson(res.data as Map<String, dynamic>);
  }
}
