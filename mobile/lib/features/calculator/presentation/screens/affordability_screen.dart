import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/affordability_result.dart';

class AffordabilityScreen extends StatefulWidget {
  const AffordabilityScreen({super.key});

  @override
  State<AffordabilityScreen> createState() => _AffordabilityScreenState();
}

class _AffordabilityScreenState extends State<AffordabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  AffordabilityResult? _result;
  String? _error;

  @override
  void dispose() {
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await AppServices.instance.affordability.check(
        _itemController.text.trim(),
        double.parse(_priceController.text.trim()),
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Can I afford this?')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Tell me what you want to buy',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _itemController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'What do you want to buy?',
                          hintText: 'e.g. iPhone 16, New laptop, PS5',
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _check(),
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          prefixText: '₹ ',
                          prefixIcon: Icon(Icons.currency_rupee_rounded),
                        ),
                        validator: (v) =>
                            (v == null || double.tryParse(v.trim()) == null)
                                ? 'Enter a valid price'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _check,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.psychology_outlined),
                        label: Text(_isLoading ? 'Analysing...' : 'Check affordability'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.danger),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 20),
              _VerdictCard(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _VerdictCard extends StatelessWidget {
  const _VerdictCard({required this.result});

  final AffordabilityResult result;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final (label, color, icon, emoji) = switch (result.verdict) {
      'SAFE_TO_BUY' => (
          'Safe to Buy',
          AppColors.success,
          Icons.check_circle_outline_rounded,
          '✅'
        ),
      'DONT_BUY' => (
          "Don't Buy Right Now",
          AppColors.danger,
          Icons.cancel_outlined,
          '❌'
        ),
      _ => (
          'Wait & Save',
          AppColors.warning,
          Icons.hourglass_bottom_rounded,
          '⏳'
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(result.reason,
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ),
            if (result.recommendedWaitMonths != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Wait',
                value: '${result.recommendedWaitMonths} months',
                color: color,
              ),
              if (result.recommendedMonthlySavings != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.savings_outlined,
                  label: 'Save monthly',
                  value: currency.format(result.recommendedMonthlySavings),
                  color: AppColors.primary,
                ),
              ],
              if (result.expectedPurchaseDate != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.event_outlined,
                  label: 'Expected date',
                  value: DateFormat.yMMMd().format(result.expectedPurchaseDate!),
                  color: AppColors.secondary,
                ),
              ],
              if (result.investmentSuggestion != null) ...[
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.account_balance_outlined,
                  label: 'Park savings in',
                  value: result.investmentSuggestion!
                      .replaceAll('_', ' ')
                      .toUpperCase(),
                  color: AppColors.accent,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 13)),
      ],
    );
  }
}
