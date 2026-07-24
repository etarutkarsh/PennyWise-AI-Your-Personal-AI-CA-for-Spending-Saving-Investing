import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/sms_parser_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../transactions/presentation/screens/add_transaction_sheet.dart';

class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _smsController = TextEditingController();
  ParsedSmsTransaction? _parsed;
  bool _parseAttempted = false;
  bool _parseFailed = false;

  @override
  void dispose() {
    _smsController.dispose();
    super.dispose();
  }

  void _parse() {
    final text = _smsController.text.trim();
    if (text.isEmpty) return;

    final result = SmsParserService.parse(text);
    setState(() {
      _parseAttempted = true;
      _parsed = result;
      _parseFailed = result == null;
    });
  }

  void _openAddSheet() {
    if (_parsed == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddTransactionSheet(
        initialAmount: _parsed!.amount,
        initialMerchant: _parsed!.merchant,
        initialDirection: _parsed!.direction,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import from SMS')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Platform note
          if (kIsWeb)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SMS auto-capture is available on Android only. '
                      'You can still paste an SMS below to parse it.',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          if (!kIsWeb) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SMS Auto-Import',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Full auto-capture from SMS inbox coming soon on Android. '
                    'For now, paste a bank SMS below to parse and import it.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Paste SMS section
          const Text(
            'Paste Bank SMS',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _smsController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Paste your bank SMS here...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppColors.background,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _parse,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Parse & Import'),
          ),

          // Parse result
          if (_parseAttempted) ...[
            const SizedBox(height: 20),
            if (_parseFailed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Could not read this SMS. Try a different bank message.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )
            else if (_parsed != null)
              _ParsedPreviewCard(
                parsed: _parsed!,
                onAddTransaction: _openAddSheet,
              ),
          ],

          const SizedBox(height: 28),
          const _SupportedFormatsCard(),
        ],
      ),
    );
  }
}

class _ParsedPreviewCard extends StatelessWidget {
  const _ParsedPreviewCard({
    required this.parsed,
    required this.onAddTransaction,
  });

  final ParsedSmsTransaction parsed;
  final VoidCallback onAddTransaction;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final isDebit = parsed.direction == 'DEBIT';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'SMS Parsed Successfully',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _PreviewRow(
                  label: 'Amount',
                  value: currency.format(parsed.amount),
                  valueColor: isDebit ? AppColors.danger : AppColors.success,
                ),
                const SizedBox(height: 10),
                _PreviewRow(
                  label: 'Type',
                  value: isDebit ? 'Spent (Debit)' : 'Received (Credit)',
                ),
                if (parsed.merchant != null) ...[
                  const SizedBox(height: 10),
                  _PreviewRow(label: 'Merchant', value: parsed.merchant!),
                ],
                if (parsed.accountLast4 != null) ...[
                  const SizedBox(height: 10),
                  _PreviewRow(
                      label: 'Account', value: '****${parsed.accountLast4}'),
                ],
                const SizedBox(height: 10),
                _PreviewRow(
                  label: 'Date',
                  value: DateFormat('d MMM yyyy').format(parsed.transactionDate),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton.icon(
              onPressed: onAddTransaction,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Transaction'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportedFormatsCard extends StatelessWidget {
  const _SupportedFormatsCard();

  static const _examples = [
    (
      'HDFC Bank',
      'Rs.1,500 debited from a/c XXXX1234 to Swiggy on 24-07-2026. '
          'Avl Bal: Rs.12,450.00'
    ),
    (
      'SBI',
      'Your A/c no. XX9876 is debited by INR 2,000.00 on 24/07/2026 '
          'at AMAZON. Avl. Balance: INR 34,500.00'
    ),
    (
      'ICICI Bank',
      'ICICI Bank: Rs 500.00 credited to A/c XX5432 on 24-Jul-2026. '
          'Avl Bal: Rs 8,200.50'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.format_list_bulleted_rounded,
                    color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Text(
                  'Supported Formats',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._examples.map((ex) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.$1,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ex.$2,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
