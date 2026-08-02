import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/category_model.dart';
import '../../domain/entities/transaction_entity.dart';

class EditTransactionSheet extends StatefulWidget {
  const EditTransactionSheet({super.key, required this.transaction});

  final TransactionEntity transaction;

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late String _direction;
  String? _selectedCategoryId;
  String? _selectedPaymentMethod;
  bool _recurring = false;
  List<CategoryModel> _categories = [];
  bool _isSubmitting = false;

  static const _paymentMethods = ['UPI', 'CARD', 'CASH', 'NETBANKING', 'WALLET'];

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    _amountController = TextEditingController(
      text: txn.amount % 1 == 0
          ? txn.amount.toStringAsFixed(0)
          : txn.amount.toStringAsFixed(2),
    );
    _merchantController = TextEditingController(text: txn.merchant);
    _noteController = TextEditingController(text: txn.note ?? '');
    _direction = txn.direction;
    _selectedCategoryId = txn.categoryId;
    _selectedPaymentMethod = txn.paymentMethod;
    _recurring = txn.recurring;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AppServices.instance.categories.getAll();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  List<CategoryModel> get _filteredCategories => _categories
      .where((c) =>
          _direction == 'DEBIT' ? c.type == 'EXPENSE' : c.type == 'INCOME')
      .toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final updated = await AppServices.instance.transactions.update(
        widget.transaction.id,
        amount: double.parse(_amountController.text.trim()),
        merchant: _merchantController.text.trim().isEmpty
            ? 'Manual entry'
            : _merchantController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        categoryId: _selectedCategoryId,
        paymentMethod: _selectedPaymentMethod,
        recurring: _recurring,
      );
      if (mounted) Navigator.of(context).pop(updated);
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
    _noteController.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Edit Transaction',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Direction toggle (display-only — direction cannot change on edit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (_direction == 'DEBIT'
                          ? AppColors.danger
                          : AppColors.success)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_direction == 'DEBIT'
                            ? AppColors.danger
                            : AppColors.success)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _direction == 'DEBIT'
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                      color: _direction == 'DEBIT'
                          ? AppColors.danger
                          : AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _direction == 'DEBIT' ? 'Expense' : 'Income',
                      style: GoogleFonts.dmSans(
                        color: _direction == 'DEBIT'
                            ? AppColors.danger
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
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

              // Merchant
              TextFormField(
                controller: _merchantController,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Merchant',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 12),

              // Note
              TextFormField(
                controller: _noteController,
                textInputAction: TextInputAction.next,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 12),

              // Category
              if (_filteredCategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  dropdownColor: AppColors.surface,
                  style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                  items: _filteredCategories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.icon}  ${c.name}'),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              const SizedBox(height: 12),

              // Payment method
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment method (optional)',
                  prefixIcon: Icon(Icons.payment_rounded),
                ),
                dropdownColor: AppColors.surface,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                items: _paymentMethods
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPaymentMethod = v),
              ),
              const SizedBox(height: 8),

              // Recurring toggle
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _recurring,
                activeThumbColor: AppColors.orange,
                title: Text(
                  'Recurring transaction',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                onChanged: (v) => setState(() => _recurring = v),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
