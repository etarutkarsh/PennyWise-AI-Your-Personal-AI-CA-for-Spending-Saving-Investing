import '../../core/services/network/api_client.dart';

class AssetModel {
  const AssetModel({
    required this.id,
    required this.assetType,
    required this.name,
    required this.value,
    this.asOfDate,
  });

  final String id;
  final String assetType;
  final String name;
  final double value;
  final String? asOfDate;

  factory AssetModel.fromJson(Map<String, dynamic> json) => AssetModel(
        id: json['id'].toString(),
        assetType: json['assetType'] as String,
        name: json['name'] as String? ?? '',
        value: (json['value'] as num).toDouble(),
        asOfDate: json['asOfDate']?.toString(),
      );
}

class LiabilityModel {
  const LiabilityModel({
    required this.id,
    required this.liabilityType,
    required this.name,
    required this.outstanding,
    this.monthlyEmi,
    this.interestRate,
    this.asOfDate,
  });

  final String id;
  final String liabilityType;
  final String name;
  final double outstanding;
  final double? monthlyEmi;
  final double? interestRate;
  final String? asOfDate;

  factory LiabilityModel.fromJson(Map<String, dynamic> json) => LiabilityModel(
        id: json['id'].toString(),
        liabilityType: json['liabilityType'] as String,
        name: json['name'] as String? ?? '',
        outstanding: (json['outstanding'] as num).toDouble(),
        monthlyEmi: (json['monthlyEmi'] as num?)?.toDouble(),
        interestRate: (json['interestRate'] as num?)?.toDouble(),
        asOfDate: json['asOfDate']?.toString(),
      );
}

class NetWorthSummary {
  const NetWorthSummary({
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.assets,
    required this.liabilities,
  });

  final double totalAssets;
  final double totalLiabilities;
  final double netWorth;
  final List<AssetModel> assets;
  final List<LiabilityModel> liabilities;

  factory NetWorthSummary.fromJson(Map<String, dynamic> json) => NetWorthSummary(
        totalAssets: (json['totalAssets'] as num).toDouble(),
        totalLiabilities: (json['totalLiabilities'] as num).toDouble(),
        netWorth: (json['netWorth'] as num).toDouble(),
        assets: (json['assets'] as List<dynamic>)
            .map((e) => AssetModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        liabilities: (json['liabilities'] as List<dynamic>)
            .map((e) => LiabilityModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class NetWorthRepository {
  NetWorthRepository(this._client);

  final ApiClient _client;

  Future<NetWorthSummary> getSummary() async {
    final res = await _client.dio.get('/net-worth/summary');
    return NetWorthSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AssetModel> createAsset({
    required String assetType,
    required String name,
    required double value,
  }) async {
    final res = await _client.dio.post('/net-worth/assets', data: {
      'assetType': assetType,
      'name': name,
      'value': value,
    });
    return AssetModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAsset(String id) async {
    await _client.dio.delete('/net-worth/assets/$id');
  }

  Future<LiabilityModel> createLiability({
    required String liabilityType,
    required String name,
    required double outstanding,
    double? monthlyEmi,
    double? interestRate,
  }) async {
    final data = <String, dynamic>{
      'liabilityType': liabilityType,
      'name': name,
      'outstanding': outstanding,
    };
    if (monthlyEmi != null) data['monthlyEmi'] = monthlyEmi;
    if (interestRate != null) data['interestRate'] = interestRate;
    final res = await _client.dio.post('/net-worth/liabilities', data: data);
    return LiabilityModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteLiability(String id) async {
    await _client.dio.delete('/net-worth/liabilities/$id');
  }
}
