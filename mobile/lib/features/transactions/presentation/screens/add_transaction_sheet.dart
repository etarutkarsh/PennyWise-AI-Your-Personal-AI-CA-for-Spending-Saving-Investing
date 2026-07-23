import 'package:flutter/material.dart';

/// Manual transaction entry - Feature 1 fallback when SMS/notification
/// auto-detection isn't available or the user wants to log something by hand.
/// POSTs to /transactions with source = "MANUAL".
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  String _direction = 'DEBIT';

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // TODO: context.read<TransactionsBloc>().add(TransactionCreateRequested(...));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add transaction', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantController,
              decoration: const InputDecoration(labelText: 'Merchant / note'),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DEBIT', label: Text('Spent')),
                ButtonSegment(value: 'CREDIT', label: Text('Received')),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() => _direction = s.first),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
