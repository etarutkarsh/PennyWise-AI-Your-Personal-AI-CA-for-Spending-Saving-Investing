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
  });

  final String id;
  final String email;
  final String fullName;
  final String userType;
  final String? phoneNumber;
  final double? monthlyIncome;
  final String? riskAppetite;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        email: json['email'] as String,
        fullName: json['fullName'] as String? ?? '',
        userType: json['userType'] as String? ?? '',
        phoneNumber: json['phoneNumber'] as String?,
        monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
        riskAppetite: json['riskAppetite'] as String?,
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
  }) async {
    final data = <String, dynamic>{};
    if (fullName != null) data['fullName'] = fullName;
    if (phoneNumber != null) data['phoneNumber'] = phoneNumber;
    if (monthlyIncome != null) data['monthlyIncome'] = monthlyIncome;
    if (riskAppetite != null) data['riskAppetite'] = riskAppetite;
    final res = await _client.dio.patch('/users/me', data: data);
    final model = UserModel.fromJson(res.data as Map<String, dynamic>);
    // Keep SharedPreferences in sync with backend salary
    if (monthlyIncome != null) {
      await UserPrefsStorage.saveSalary(monthlyIncome);
    }
    return model;
  }
}
