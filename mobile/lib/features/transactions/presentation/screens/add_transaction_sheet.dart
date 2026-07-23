import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
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
  bool _isSuggestingCategory = false;
  bool _isOcrScanning = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _suggestCategory() async {
    final merchant = _merchantController.text.trim();
    if (merchant.isEmpty || _filteredCategories.isEmpty) return;
    setState(() => _isSuggestingCategory = true);
    try {
      final suggestion = await AppServices.instance.ai
          .suggestCategory(merchant, _filteredCategories);
      if (suggestion != null && mounted) {
        setState(() => _selectedCategoryId = suggestion);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Category suggested by AI'),
              duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSuggestingCategory = false);
    }
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;

    setState(() => _isOcrScanning = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final inputImage = InputImage.fromFile(File(picked.path));
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognized.text;
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in image. Try a clearer photo.')),
          );
        }
        return;
      }

      _parseReceiptText(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isOcrScanning = false);
    }
  }

  void _parseReceiptText(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // Extract total amount — look for patterns like ₹1,234 or TOTAL 1234.00
    final amountPatterns = [
      RegExp(r'(?:total|grand total|amount|net amount|bill amount)\s*[:\-]?\s*₹?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'₹\s*([\d,]+\.?\d*)'),
      RegExp(r'rs\.?\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'\b(\d{2,6}\.?\d{0,2})\b'),
    ];

    String? amount;
    for (final pattern in amountPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        amount = match.group(1)?.replaceAll(',', '');
        if (amount != null && double.tryParse(amount) != null) break;
      }
    }

    // Extract merchant — usually the first non-numeric line
    String? merchant;
    for (final line in lines.take(5)) {
      if (line.length > 3 &&
          !RegExp(r'^\d').hasMatch(line) &&
          !line.toLowerCase().contains('invoice') &&
          !line.toLowerCase().contains('receipt')) {
        merchant = line;
        break;
      }
    }

    if (amount != null) _amountController.text = amount;
    if (merchant != null && _merchantController.text.isEmpty) {
      _merchantController.text = merchant;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(amount != null
              ? 'Receipt scanned! Review and save.'
              : 'Scanned text found — fill in the amount manually.'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

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
      // Record activity for streak tracking
      await UserPrefsStorage.recordActivity();
      await UserPrefsStorage.addAchievement('first_transaction');
      if (mounted) Navigator.of(context).pop(tx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
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
        left: 20, right: 20, top: 20,
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
                Text('Add Transaction', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Tooltip(
                  message: 'Scan receipt',
                  child: IconButton(
                    onPressed: _isOcrScanning ? null : _scanReceipt,
                    icon: _isOcrScanning
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.document_scanner_outlined, color: AppColors.primary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'DEBIT', label: Text('Spent'),
                    icon: Icon(Icons.arrow_upward_rounded)),
                ButtonSegment(value: 'CREDIT', label: Text('Received'),
                    icon: Icon(Icons.arrow_downward_rounded)),
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
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (v) => (v == null || double.tryParse(v.trim()) == null)
                  ? 'Enter a valid amount'
                  : null,
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _merchantController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Merchant / note (optional)',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'AI: suggest category',
                  child: IconButton.filledTonal(
                    onPressed: _isSuggestingCategory ? null : _suggestCategory,
                    icon: _isSuggestingCategory
                        ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
                  ),
                ),
              ],
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
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
