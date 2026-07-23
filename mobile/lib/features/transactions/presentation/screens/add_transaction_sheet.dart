import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/category_model.dart';

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
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AppServices.instance.categories.getAll();
      if (mounted) {
        setState(() {
          // Filter to show expense categories for DEBIT, income for CREDIT
          _categories = cats;
        });
      }
    } catch (_) {
      // Categories are optional — submit will still work without category
    }
  }

  List<CategoryModel> get _filteredCategories => _categories
      .where((c) =>
          _direction == 'DEBIT' ? c.type == 'EXPENSE' : c.type == 'INCOME')
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final tx = await AppServices.instance.transactions.create(
        amount: double.parse(_amountController.text.trim()),
        merchant: _merchantController.text.trim().isEmpty
            ? 'Manual entry'
            : _merchantController.text.trim(),
        direction: _direction,
        categoryId: _selectedCategoryId,
      );
      if (mounted) Navigator.of(context).pop(tx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Add Transaction',
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Spent / Received toggle
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'DEBIT',
                  label: Text('Spent'),
                  icon: Icon(Icons.arrow_upward_rounded),
                ),
                ButtonSegment(
                  value: 'CREDIT',
                  label: Text('Received'),
                  icon: Icon(Icons.arrow_downward_rounded),
                ),
              ],
              selected: {_direction},
              onSelectionChanged: (s) => setState(() {
                _direction = s.first;
                _selectedCategoryId = null;
              }),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (v) =>
                  (v == null || double.tryParse(v.trim()) == null)
                      ? 'Enter a valid amount'
                      : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantController,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Merchant / note (optional)',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 12),
            if (_filteredCategories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _filteredCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icon}  ${c.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
