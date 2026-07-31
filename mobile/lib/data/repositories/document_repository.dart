import '../models/document_model.dart';
import '../../core/services/network/api_client.dart';

class DocumentRepository {
  const DocumentRepository(this._client);
  final ApiClient _client;

  Future<List<DocumentModel>> getAll({String? type}) async {
    final res = await _client.dio.get(
      '/documents',
      queryParameters: type != null ? {'type': type} : null,
    );
    return (res.data as List)
        .map((j) => DocumentModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<DocumentModel> create({
    required String documentType,
    String? originalFilename,
    String? fileUrl,
    String? financialYear,
    String? taxCategory,
    String? linkedTransactionId,
  }) async {
    final res = await _client.dio.post('/documents', data: {
      'documentType': documentType,
      if (originalFilename != null) 'originalFilename': originalFilename,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (financialYear != null) 'financialYear': financialYear,
      if (taxCategory != null) 'taxCategory': taxCategory,
      if (linkedTransactionId != null) 'linkedTransactionId': linkedTransactionId,
    });
    return DocumentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<DocumentModel> verify(String id) async {
    final res = await _client.dio.patch('/documents/$id/verify');
    return DocumentModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _client.dio.delete('/documents/$id');
  }
}
