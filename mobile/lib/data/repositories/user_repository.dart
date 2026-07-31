import '../../core/services/network/api_client.dart';
import '../../core/services/storage/user_prefs_storage.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.phoneNumber,
    this.monthlyIncome,
    this.riskAppetite,
    this.pan,
    this.taxRegime,
    this.financialYearStart,
  });

  final String id;
  final String email;
  final String fullName;
  final String userType;
  final String? phoneNumber;
  final double? monthlyIncome;
  final String? riskAppetite;
  // Tax-ready fields
  final String? pan;
  final String? taxRegime;        // NEW | OLD
  final int? financialYearStart;  // 4 = April (Indian FY)

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        email: json['email'] as String,
        fullName: json['fullName'] as String? ?? '',
        userType: json['userType'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
        riskAppetite: json['riskAppetite'] as String?,
        pan: json['pan'] as String?,
        taxRegime: json['taxRegime'] as String?,
        financialYearStart: json['financialYearStart'] as int?,
      );
}

class UserRepository {
  UserRepository(this._client);

  final ApiClient _client;

  Future<UserModel> getMe() async {
    final res = await _client.dio.get('/users/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> updateMe({
    String? fullName,
    String? phoneNumber,
    double? monthlyIncome,
    String? riskAppetite,
    String? pan,
    String? taxRegime,
    int? financialYearStart,
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (monthlyIncome != null) data['monthlyIncome'] = monthlyIncome;
    if (riskAppetite != null) data['riskAppetite'] = riskAppetite;
    if (pan != null) data['pan'] = pan;
    if (taxRegime != null) data['taxRegime'] = taxRegime;
    if (financialYearStart != null) data['financialYearStart'] = financialYearStart;
    final res = await _client.dio.patch('/users/me', data: data);
    final model = UserModel.fromJson(res.data as Map<String, dynamic>);
    // Keep SharedPreferences in sync with backend salary
    if (monthlyIncome != null) {
      await UserPrefsStorage.saveSalary(monthlyIncome);
    }
    return model;
  }
}
