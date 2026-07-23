import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';
import '../../data/models/category_model.dart';

/// Calls OpenAI directly from the app using the user's own API key.
/// The key is stored in FlutterSecureStorage — never sent to our backend.
class AiService {
  AiService(this._storage);

  final FlutterSecureStorage _storage;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.openai.com/v1',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  static const _model = 'gpt-4o-mini';

  Future<bool> hasKey() async {
    final key = await _storage.read(key: ApiConstants.openAiKeyStorageKey);
    return key != null && key.trim().isNotEmpty;
  }

  Future<void> saveKey(String key) async {
    await _storage.write(key: ApiConstants.openAiKeyStorageKey, value: key.trim());
  }

  Future<void> deleteKey() async {
    await _storage.delete(key: ApiConstants.openAiKeyStorageKey);
  }

  Future<String?> _getKey() => _storage.read(key: ApiConstants.openAiKeyStorageKey);

  /// Public accessor for the stored key — used by ChatScreen to send as header.
  Future<String?> getStoredKey() => _getKey();

  Future<String> _chat(String systemPrompt, String userMessage) async {
    final key = await _getKey();
    if (key == null || key.isEmpty) throw Exception('No OpenAI API key set.');

    final response = await _dio.post(
      '/chat/completions',
      options: Options(headers: {'Authorization': 'Bearer $key'}),
      data: {
        'model': _model,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userMessage},
        ],
        'max_tokens': 300,
        'temperature': 0.7,
      },
    );
    return response.data['choices'][0]['message']['content'] as String;
  }

  /// Suggests the best matching category name for a merchant.
  /// Returns null if AI key not set or call fails.
  Future<String?> suggestCategory(
      String merchant, List<CategoryModel> categories) async {
    if (!await hasKey()) return null;
    if (categories.isEmpty) return null;

    final categoryList =
        categories.map((c) => '${c.name} (${c.type})').join(', ');

    try {
      final reply = await _chat(
        'You are a personal finance assistant. Given a merchant name, '
        'return ONLY the most appropriate category name from the list provided. '
        'No explanation, just the category name.',
        'Merchant: "$merchant"\nCategories: $categoryList',
      );
      final trimmed = reply.trim();
      final match = categories.firstWhere(
        (c) => c.name.toLowerCase() == trimmed.toLowerCase(),
        orElse: () => categories.first,
      );
      return match.id;
    } catch (_) {
      return null;
    }
  }

  /// Returns 3–5 spending insight strings based on recent transaction data.
  Future<List<String>> getSpendingInsights({
    required double totalDebit,
    required double totalCredit,
    required double salary,
    required Map<String, double> spendingByCategory,
  }) async {
    if (!await hasKey()) return _staticInsights(totalDebit, salary);

    final categoryBreakdown = spendingByCategory.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}')
        .join(', ');

    try {
      final reply = await _chat(
        'You are PennyWise, a personal finance AI for Indian users. '
        'Analyse the spending data and return exactly 4 concise, actionable insights '
        'in plain English. Each insight on a new line starting with a bullet "•". '
        'Keep each insight under 20 words. Use ₹ for currency.',
        'Monthly salary: ₹${salary.toStringAsFixed(0)}\n'
        'Total spent: ₹${totalDebit.toStringAsFixed(0)}\n'
        'Total income received: ₹${totalCredit.toStringAsFixed(0)}\n'
        'Spending by category: $categoryBreakdown',
      );
      return reply
          .split('\n')
          .where((l) => l.trim().startsWith('•'))
          .map((l) => l.replaceFirst('•', '').trim())
          .where((l) => l.isNotEmpty)
          .toList();
    } catch (_) {
      return _staticInsights(totalDebit, salary);
    }
  }

  /// Returns 3 personalised savings recommendations.
  Future<List<String>> getSavingsRecommendations({
    required double salary,
    required double totalSpent,
    required String topCategory,
  }) async {
    if (!await hasKey()) return _staticRecommendations(salary, totalSpent);

    try {
      final reply = await _chat(
        'You are PennyWise, a personal finance AI for Indian users. '
        'Give exactly 3 specific, actionable savings tips. '
        'Each tip on a new line starting with "•". Under 25 words each. Use ₹.',
        'Salary: ₹${salary.toStringAsFixed(0)}, '
        'Spent this month: ₹${totalSpent.toStringAsFixed(0)}, '
        'Highest spending category: $topCategory',
      );
      return reply
          .split('\n')
          .where((l) => l.trim().startsWith('•'))
          .map((l) => l.replaceFirst('•', '').trim())
          .where((l) => l.isNotEmpty)
          .take(3)
          .toList();
    } catch (_) {
      return _staticRecommendations(salary, totalSpent);
    }
  }

  /// Returns a daily finance tip — AI-generated if key set, static otherwise.
  Future<String> getDailyTip() async {
    if (!await hasKey()) return _staticTips[DateTime.now().day % _staticTips.length];

    try {
      return await _chat(
        'You are PennyWise, a personal finance coach for young Indians. '
        'Give ONE short, motivating finance tip for today. '
        'Max 20 words. No quotes, no bullet.',
        'Give me today\'s finance tip.',
      );
    } catch (_) {
      return _staticTips[DateTime.now().day % _staticTips.length];
    }
  }

  List<String> _staticInsights(double spent, double salary) => [
        'You spent ₹${spent.toStringAsFixed(0)} this month.',
        salary > 0 && spent > salary * 0.8
            ? 'You\'re spending over 80% of your income — try to cut back.'
            : 'Your spending is within a healthy range.',
        'Track every expense to find hidden savings.',
        'Set a budget for your top spending category.',
      ];

  List<String> _staticRecommendations(double salary, double spent) => [
        'Save at least 20% of your salary (₹${(salary * 0.2).toStringAsFixed(0)}) each month.',
        'Cut subscriptions you haven\'t used in 30 days.',
        'Move savings to a high-yield liquid fund on payday.',
      ];

  /// Returns spending predictions for next month based on last 3 months of data.
  Future<List<String>> getSpendingPredictions({
    required Map<String, double> avgSpendingByCategory,
    required double avgMonthlyTotal,
  }) async {
    if (!await hasKey()) return _staticPredictions(avgMonthlyTotal);

    final breakdown = avgSpendingByCategory.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}/mo avg')
        .join(', ');

    try {
      final reply = await _chat(
        'You are PennyWise, a finance AI for Indian users. '
        'Predict next month\'s spending based on the 3-month averages. '
        'Return exactly 4 predictions, each on a new line starting with "•". '
        'Format: "• You\'ll likely spend ₹X on Y next month" or similar. Under 20 words each.',
        'Average monthly total: ₹${avgMonthlyTotal.toStringAsFixed(0)}\n'
        'Average by category: $breakdown',
      );
      return reply
          .split('\n')
          .where((l) => l.trim().startsWith('•'))
          .map((l) => l.replaceFirst('•', '').trim())
          .where((l) => l.isNotEmpty)
          .take(4)
          .toList();
    } catch (_) {
      return _staticPredictions(avgMonthlyTotal);
    }
  }

  List<String> _staticPredictions(double avg) => [
        'Your total spending next month will likely be around ₹${avg.toStringAsFixed(0)}.',
        'Track your top spending category closely to stay under budget.',
        'Consider setting a monthly limit for discretionary spending.',
        'Review subscriptions — they tend to creep up month over month.',
      ];

  static const _staticTips = [
    'Pay yourself first — transfer savings the moment your salary arrives.',
    'The best investment is the one you start today, not someday.',
    'Track every ₹100 you spend — small leaks sink big ships.',
    'An emergency fund of 6 months\' expenses is your financial superpower.',
    'Automate your SIP so investing happens without willpower.',
    'Cut one subscription today — that\'s ₹1,200+ back per year.',
    'Compare prices before buying anything over ₹500.',
    'Your future self will thank you for every rupee you save today.',
    'Avoid lifestyle inflation — when income rises, save the difference first.',
    'Invest in index funds for long-term wealth with minimal effort.',
  ];
}
