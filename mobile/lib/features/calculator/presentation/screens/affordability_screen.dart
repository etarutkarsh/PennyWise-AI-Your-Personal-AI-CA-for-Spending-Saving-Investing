import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/affordability_result.dart';

/// Feature 4 - Affordability Checker: "Can I actually afford this?"
/// Calls POST /affordability/check on the backend (AffordabilityController)
/// and renders the verdict/reason/wait-time it returns.
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
    });

    // TODO: replace with a real call through ApiClient:
    //   final response = await apiClient.dio.post('/affordability/check', data: {
    //     'itemName': _itemController.text,
    //     'price': double.parse(_priceController.text),
    //   });
    //   final result = AffordabilityResult.fromJson(response.data);
    await Future.delayed(const Duration(milliseconds: 800));
    final result = AffordabilityResult(
      verdict: 'WAIT_AND_SAVE',
      reason: 'Buying this today would reduce your emergency fund below the recommended safety level.',
      recommendedWaitMonths: 5,
      recommendedMonthlySavings: 15000,
      expectedPurchaseDate: DateTime.now().add(const Duration(days: 150)),
      investmentSuggestion: 'liquid_fund',
    );

    if (mounted) setState(() { _isLoading = false; _result = result; });
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
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _itemController,
                    decoration: const InputDecoration(labelText: 'What do you want to buy?'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ '),
                    validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid price' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _check,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Check affordability'),
                  ),
                ],
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
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
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final (label, color, icon) = switch (result.verdict) {
      'SAFE_TO_BUY' => ('Safe to buy', AppColors.success, Icons.check_circle_outline_rounded),
      'DONT_BUY' => ("Don't buy", AppColors.danger, Icons.cancel_outlined),
      _ => ('Wait and save', AppColors.warning, Icons.hourglass_bottom_rounded),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            Text(result.reason),
            if (result.recommendedWaitMonths != null) ...[
              const Divider(height: 24),
              _InfoRow(label: 'Wait', value: '${result.recommendedWaitMonths} months'),
              if (result.recommendedMonthlySavings != null)
                _InfoRow(label: 'Save', value: '${currency.format(result.recommendedMonthlySavings)}/month'),
              if (result.expectedPurchaseDate != null)
                _InfoRow(label: 'Expected purchase date', value: DateFormat.yMMMd().format(result.expectedPurchaseDate!)),
              if (result.investmentSuggestion != null)
                _InfoRow(label: 'Park savings in', value: result.investmentSuggestion!.replaceAll('_', ' ')),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
