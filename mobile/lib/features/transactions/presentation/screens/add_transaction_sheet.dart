import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/category_model.dart';

// ---------------------------------------------------------------------------
// Quick-add category grid constants
// ---------------------------------------------------------------------------
const _quickCategories = [
  ('🍔', 'Food'),
  ('🚗', 'Transport'),
  ('🛍', 'Shopping'),
  ('💡', 'Bills'),
  ('💰', 'Salary'),
  ('📈', 'Investment'),
  ('🏥', 'Health'),
  ('🎬', 'Entertainment'),
  ('✈', 'Travel'),
  ('📚', 'Education'),
  ('💸', 'Other'),
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({
    super.key,
    this.initialAmount,
    this.initialMerchant,
    this.initialDirection,
  });

  final double? initialAmount;
  final String? initialMerchant;
  final String? initialDirection;

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  // ── Mode ───────────────────────────────────────────────────────────────
  bool _advancedMode = false;

  // ── Stepper state ──────────────────────────────────────────────────────
  int _step = 0; // 0=amount, 1=category, 2=merchant

  // ── Shared form state ──────────────────────────────────────────────────
  final _amountFormKey = GlobalKey<FormState>();
  final _advancedFormKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _noteController;
  late String _direction;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  List<CategoryModel> _categories = [];
  bool _isSubmitting = false;
  bool _isSuggestingCategory = false;
  bool _isOcrScanning = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount != null
          ? widget.initialAmount!.toStringAsFixed(
              widget.initialAmount! % 1 == 0 ? 0 : 2)
          : '',
    );
    _merchantController =
        TextEditingController(text: widget.initialMerchant ?? '');
    _noteController = TextEditingController();
    _direction = widget.initialDirection ?? 'DEBIT';
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

  // ── Stepper navigation ─────────────────────────────────────────────────
  void _nextStep() {
    if (_step == 0) {
      if (!_amountFormKey.currentState!.validate()) return;
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    }
  }

  void _prevStep() {
    if (_step > 0) setState(() => _step--);
  }

  void _selectQuickCategory(String emoji, String name) {
    // Try to match to a backend category by name
    final match = _filteredCategories
        .where((c) => c.name.toLowerCase() == name.toLowerCase())
        .map((c) => c.id)
        .firstOrNull;

    setState(() {
      _selectedCategoryId = match;
      _selectedCategoryName = name;
      _step = 2;
    });
  }

  // ── OCR ────────────────────────────────────────────────────────────────
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
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final recognized = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognized.text;
      if (text.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('No text found in image. Try a clearer photo.')),
          );
        }
        return;
      }
      _parseReceiptText(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('OCR failed: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isOcrScanning = false);
    }
  }

  void _parseReceiptText(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amountPatterns = [
      RegExp(
          r'(?:total|grand total|amount|net amount|bill amount)\s*[:\-]?\s*₹?\s*([\d,]+\.?\d*)',
          caseSensitive: false),
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

  // ── AI category suggestion ─────────────────────────────────────────────
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

  // ── Submit ──────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (_advancedMode) {
      if (!_advancedFormKey.currentState!.validate()) return;
    }
    setState(() => _isSubmitting = true);
    try {
      final merchant = _merchantController.text.trim();
      final tx = await AppServices.instance.transactions.create(
        amount: double.parse(_amountController.text.trim()),
        merchant: merchant.isEmpty ? 'Manual entry' : merchant,
        direction: _direction,
        categoryId: _selectedCategoryId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
      await UserPrefsStorage.recordActivity();
      await UserPrefsStorage.addAchievement('first_transaction');
      if (mounted) Navigator.of(context).pop(tx);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(friendlyError(e)),
              backgroundColor: AppColors.danger),
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

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _advancedMode ? _buildAdvancedForm() : _buildStepperForm(),
    );
  }

  // ── Stepper form ────────────────────────────────────────────────────────
  Widget _buildStepperForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title row
        Row(
          children: [
            if (_step > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textSecondary),
                onPressed: _prevStep,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (_step > 0) const SizedBox(width: 8),
            Text(
              _stepTitle,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _advancedMode = true),
              child: Text(
                'Advanced',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.close, color: AppColors.textSecondary),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),

        // Step indicator dots
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? AppColors.orange
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        // Step content
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: _buildStep(),
          ),
        ),
      ],
    );
  }

  String get _stepTitle {
    switch (_step) {
      case 0:
        return 'How much?';
      case 1:
        return 'Pick category';
      default:
        return 'Who paid?';
    }
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildAmountStep();
      case 1:
        return _buildCategoryStep();
      default:
        return _buildMerchantStep();
    }
  }

  // Step 0: amount + direction
  Widget _buildAmountStep() {
    return Form(
      key: _amountFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Direction toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'DEBIT',
                  label: Text('Spent'),
                  icon: Icon(Icons.arrow_upward_rounded)),
              ButtonSegment(
                  value: 'CREDIT',
                  label: Text('Received'),
                  icon: Icon(Icons.arrow_downward_rounded)),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() {
              _direction = s.first;
              _selectedCategoryId = null;
              _selectedCategoryName = null;
            }),
          ),
          const SizedBox(height: 16),
          // Amount field
          TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            autofocus: true,
            style: GoogleFonts.dmSans(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              prefixText: '₹ ',
              prefixStyle: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            validator: (v) =>
                (v == null || double.tryParse(v.trim()) == null)
                    ? 'Enter a valid amount'
                    : null,
            onFieldSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _nextStep,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  // Step 1: category grid
  Widget _buildCategoryStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: _quickCategories.length,
          itemBuilder: (_, i) {
            final (emoji, name) = _quickCategories[i];
            final isSelected = _selectedCategoryName == name;
            return GestureDetector(
              onTap: () => _selectQuickCategory(emoji, name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange.withValues(alpha: 0.15)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.orange.withValues(alpha: 0.5)
                        : AppColors.border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? AppColors.orange
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => setState(() => _step = 2),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.border),
            foregroundColor: AppColors.textSecondary,
          ),
          child: Text(
            'Skip',
            style: GoogleFonts.dmSans(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  // Step 2: merchant + submit
  Widget _buildMerchantStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Selected category chip (if any)
        if (_selectedCategoryName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              children: [
                Chip(
                  backgroundColor:
                      AppColors.orange.withValues(alpha: 0.1),
                  side: BorderSide(
                      color: AppColors.orange.withValues(alpha: 0.3)),
                  label: Text(
                    _selectedCategoryName!,
                    style: GoogleFonts.dmSans(
                      color: AppColors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded,
                      size: 14, color: AppColors.orange),
                  onDeleted: () => setState(() {
                    _selectedCategoryName = null;
                    _selectedCategoryId = null;
                    _step = 1;
                  }),
                ),
              ],
            ),
          ),
        // Merchant field
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextFormField(
                controller: _merchantController,
                textInputAction: TextInputAction.done,
                autofocus: true,
                style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Merchant (optional)',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'AI: suggest category',
              child: IconButton.filledTonal(
                onPressed: _isSuggestingCategory ? null : _suggestCategory,
                icon: _isSuggestingCategory
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.auto_awesome_rounded,
                        color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: 'Scan receipt',
              child: IconButton.filledTonal(
                onPressed: _isOcrScanning ? null : _scanReceipt,
                icon: _isOcrScanning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.document_scanner_outlined,
                        color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Note field
        TextFormField(
          controller: _noteController,
          textInputAction: TextInputAction.done,
          style: GoogleFonts.dmSans(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Note (optional)',
            prefixIcon: Icon(Icons.notes_rounded),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Transaction'),
        ),
      ],
    );
  }

  // ── Advanced form (single-screen fallback) ──────────────────────────────
  Widget _buildAdvancedForm() {
    return Form(
      key: _advancedFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Add Transaction',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _advancedMode = false),
                child: Text(
                  'Quick',
                  style:
                      GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              Tooltip(
                message: 'Scan receipt',
                child: IconButton(
                  onPressed: _isOcrScanning ? null : _scanReceipt,
                  icon: _isOcrScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.document_scanner_outlined,
                          color: AppColors.primary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                  value: 'DEBIT',
                  label: Text('Spent'),
                  icon: Icon(Icons.arrow_upward_rounded)),
              ButtonSegment(
                  value: 'CREDIT',
                  label: Text('Received'),
                  icon: Icon(Icons.arrow_downward_rounded)),
            ],
            selected: {_direction},
            onSelectionChanged: (s) => setState(() {
              _direction = s.first;
              _selectedCategoryId = null;
              _selectedCategoryName = null;
            }),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            autofocus: true,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _merchantController,
                  textInputAction: TextInputAction.next,
                  style:
                      GoogleFonts.dmSans(color: AppColors.textPrimary),
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
                  onPressed:
                      _isSuggestingCategory ? null : _suggestCategory,
                  icon: _isSuggestingCategory
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save Transaction'),
          ),
        ],
      ),
    );
  }
}
