import '../../core/services/network/api_client.dart';
import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._client);

  final ApiClient _client;

  Future<List<CategoryModel>> getAll() async {
    final res = await _client.dio.get('/categories');
    return (res.data as List)
        .map((j) => CategoryModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
