import '../../core/services/network/api_client.dart';

class CategorySpend {
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage;

  const CategorySpend({
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
  });

  factory CategorySpend.fromJson(Map<String, dynamic> j) => CategorySpend(
        categoryName: j['categoryName'] as String? ?? 'Other',
        categoryIcon: j['categoryIcon'] as String? ?? '💸',
        amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0.0,
      );
}

class MonthReport {
  final String period; // "2026-08"
  final double totalSpend;
  final double totalIncome;
  final double netSavings;
  final List<CategorySpend> byCategory;

  const MonthReport({
    required this.period,
    required this.totalSpend,
    required this.totalIncome,
    required this.netSavings,
    required this.byCategory,
  });

  factory MonthReport.fromJson(Map<String, dynamic> j) => MonthReport(
        period: j['period'] as String? ?? '',
        totalSpend: (j['totalSpend'] as num?)?.toDouble() ?? 0.0,
        totalIncome: (j['totalIncome'] as num?)?.toDouble() ?? 0.0,
        netSavings: (j['netSavings'] as num?)?.toDouble() ?? 0.0,
        byCategory: (j['byCategory'] as List? ?? [])
            .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  String get monthLabel {
    if (period.length < 7) return period;
    final parts = period.split('-');
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m = int.tryParse(parts[1]) ?? 0;
    final y = parts[0].substring(2); // "26"
    return '${months[m]} $y';
  }

  double get savingsRate =>
      totalIncome > 0 ? (netSavings / totalIncome * 100) : 0.0;
}

class ReportRepository {
  ReportRepository(this._client);
  final ApiClient _client;

  Future<MonthReport> getMonthly({required int year, required int month}) async {
    final res = await _client.dio.get(
      '/reports/monthly',
      queryParameters: {'year': year, 'month': month},
    );
    return MonthReport.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<MonthReport>> getTrend() async {
    final res = await _client.dio.get('/reports/trend');
    return (res.data as List)
        .map((e) => MonthReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
