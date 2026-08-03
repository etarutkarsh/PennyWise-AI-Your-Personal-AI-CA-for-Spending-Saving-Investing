import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/ingestion/ingestion_source.dart';
import '../../../../core/services/sms/sms_capture_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/category_model.dart';

// ---------------------------------------------------------------------------
// Data holder for a single parsed row in the bulk-import table
// ---------------------------------------------------------------------------
class _ParsedRow {
  _ParsedRow(this.event)
      : selected = true,
        suggestedCategoryId = null,
        selectedCategoryId = null,
        loadingCategory = true;

  final RawFinancialEvent event;
  bool selected;
  String? suggestedCategoryId;
  String? selectedCategoryId;
  bool loadingCategory;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class SmsImportScreen extends StatefulWidget {
  const SmsImportScreen({super.key});

  @override
  State<SmsImportScreen> createState() => _SmsImportScreenState();
}

class _SmsImportScreenState extends State<SmsImportScreen> {
  final _rawController = TextEditingController();

  List<_ParsedRow> _rows = [];
  List<CategoryModel> _categories = [];
  bool _importing = false;
  bool _readingPhone = false;
  StreamSubscription<RawFinancialEvent>? _liveSub;

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _dateFmt = DateFormat('d MMM');

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _liveSub =
        GetIt.instance<SmsCaptureService>().liveTransactions.listen((event) {
      if (!mounted) return;
      final isDupe = _isDuplicate(event);
      if (isDupe) return;
      final row = _ParsedRow(event);
      setState(() => _rows = [row, ..._rows]);
      _suggestCategory(row);
    });
  }

  @override
  void dispose() {
    _rawController.dispose();
    _liveSub?.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AppServices.instance.categories.getAll();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  bool _isDuplicate(RawFinancialEvent event) {
    return _rows.any((r) =>
        r.event.amount == event.amount &&
        r.event.direction == event.direction &&
        r.event.timestamp.year == event.timestamp.year &&
        r.event.timestamp.month == event.timestamp.month &&
        r.event.timestamp.day == event.timestamp.day);
  }

  // -------------------------------------------------------------------------
  // Read from phone (Android only)
  // -------------------------------------------------------------------------
  Future<void> _readFromPhone() async {
    final status = await Permission.sms.request();
    if (!mounted) return;

    if (status.isPermanentlyDenied) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('SMS permission required'),
          content: const Text(
            'PennyWise needs SMS access to read your bank messages. '
            'Please enable it in Settings → App → Permissions.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    if (!status.isGranted) return;

    setState(() => _readingPhone = true);
    try {
      final events = await GetIt.instance<SmsCaptureService>().fetchInbox(
        from: DateTime.now().subtract(const Duration(days: 90)),
        to: DateTime.now(),
      );

      final newRows = <_ParsedRow>[];
      for (final event in events) {
        if (_isDuplicate(event)) continue;
        newRows.add(_ParsedRow(event));
      }

      if (!mounted) return;

      if (newRows.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No new bank transactions found in last 90 days.'),
          ),
        );
        return;
      }

      setState(() => _rows = [..._rows, ...newRows]);
      for (final row in newRows) {
        _suggestCategory(row);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Found ${newRows.length} new transaction${newRows.length == 1 ? '' : 's'} from inbox'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not read SMS: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _readingPhone = false);
    }
  }

  // -------------------------------------------------------------------------
  // Parse action (paste mode)
  // -------------------------------------------------------------------------
  void _parse() {
    final text = _rawController.text.trim();
    if (text.isEmpty) return;

    final chunks = text.split(RegExp(r'\n\n+'));
    final service = GetIt.instance<SmsCaptureService>();

    final newRows = <_ParsedRow>[];
    for (final chunk in chunks) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final event = service.processMessage(trimmed, '');
      if (event == null) continue;
      if (_isDuplicate(event)) continue;
      newRows.add(_ParsedRow(event));
    }

    if (newRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions found in pasted text.')),
      );
      return;
    }

    setState(() => _rows = [..._rows, ...newRows]);
    for (final row in newRows) {
      _suggestCategory(row);
    }
  }

  Future<void> _suggestCategory(_ParsedRow row) async {
    try {
      final id = await AppServices.instance.ai
          .suggestCategory(row.event.rawMerchant, _categories);
      if (mounted) {
        setState(() {
          row.suggestedCategoryId = id;
          row.selectedCategoryId = id;
          row.loadingCategory = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => row.loadingCategory = false);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Import action
  // -------------------------------------------------------------------------
  Future<void> _import() async {
    final selected = _rows.where((r) => r.selected).toList();
    if (selected.isEmpty) return;

    setState(() => _importing = true);

    final imported = <_ParsedRow>[];
    String? errorMsg;

    for (final row in selected) {
      try {
        await AppServices.instance.transactions.create(
          amount: row.event.amount,
          merchant: row.event.rawMerchant,
          direction: row.event.direction,
          categoryId: row.selectedCategoryId,
          paymentMethod: row.event.paymentRail,
          transactionDate: row.event.timestamp,
        );
        imported.add(row);
      } catch (e) {
        errorMsg = friendlyError(e);
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _importing = false;
      _rows.removeWhere((r) => imported.contains(r));
      if (_rows.isEmpty) _rawController.clear();
    });

    if (imported.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${imported.length} transaction${imported.length == 1 ? '' : 's'} imported'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg), backgroundColor: AppColors.danger),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final selectedCount = _rows.where((r) => r.selected).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Import from SMS',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildInfoBanner(),
                const SizedBox(height: 20),

                TextField(
                  controller: _rawController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText:
                        'Paste bank SMS here — one or more messages...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 12),
                if (!kIsWeb && Platform.isAndroid) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _readingPhone ? null : _readFromPhone,
                      icon: _readingPhone
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.inbox_rounded),
                      label: Text(_readingPhone
                          ? 'Reading inbox…'
                          : 'Read from Phone (last 90 days)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('or paste manually',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _parse,
                    icon: const Icon(Icons.search_rounded),
                    label: const Text('Parse SMS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                if (_rows.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Parsed Transactions (${_rows.length} found)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _rows.clear()),
                        child: const Text(
                          'Clear all',
                          style:
                              TextStyle(color: AppColors.danger, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        SizedBox(width: 32),
                        Expanded(
                          flex: 3,
                          child: Text('Merchant',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Amount',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('Category',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),

                  ..._rows.map((row) => _buildRow(row)),
                ],

                const SizedBox(height: 24),
                const _SupportedFormatsCard(),
                const SizedBox(height: 80),
              ],
            ),
          ),

          if (_rows.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      (selectedCount == 0 || _importing) ? null : _import,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _importing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Import $selectedCount selected',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              kIsWeb
                  ? 'Paste one or more bank SMS below — one message per section. (SMS auto-read not available on web)'
                  : Platform.isAndroid
                      ? 'Tap "Read from Phone" to auto-import last 90 days of bank SMS, or paste messages manually below.'
                      : 'Paste one or more bank SMS below — one message per section. (SMS auto-read is Android only)',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_ParsedRow row) {
    final isDebit = row.event.direction == 'DEBIT';
    final amountColor = isDebit ? AppColors.danger : AppColors.success;
    final badgeBg = isDebit
        ? AppColors.danger.withValues(alpha: 0.12)
        : AppColors.success.withValues(alpha: 0.12);
    final badgeText = isDebit ? 'Spent' : 'Received';

    final relevantCats = _categories
        .where((c) => isDebit ? c.type == 'EXPENSE' : c.type == 'INCOME')
        .toList();

    return Dismissible(
      key: ObjectKey(row),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 20),
      ),
      onDismissed: (_) => setState(() => _rows.remove(row)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 28,
              child: Checkbox(
                value: row.selected,
                activeColor: AppColors.primary,
                onChanged: (v) =>
                    setState(() => row.selected = v ?? row.selected),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 4),

            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.event.rawMerchant,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _dateFmt.format(row.event.timestamp),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (row.event.paymentRail != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color:
                                AppColors.secondary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            row.event.paymentRail!.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currency.format(row.event.amount),
                    style: TextStyle(
                      color: amountColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                          fontSize: 10,
                          color: amountColor,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            Expanded(
              flex: 2,
              child: row.loadingCategory
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.background,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: row.selectedCategoryId,
                          isDense: true,
                          isExpanded: true,
                          hint: const Text('Category',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary)),
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textPrimary),
                          icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: AppColors.textSecondary),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('None',
                                  style: TextStyle(fontSize: 11)),
                            ),
                            ...relevantCats
                                .map((c) => DropdownMenuItem<String?>(
                                      value: c.id,
                                      child: Text(
                                        c.name,
                                        style:
                                            const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    )),
                          ],
                          onChanged: (v) =>
                              setState(() => row.selectedCategoryId = v),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Supported formats card
// ---------------------------------------------------------------------------
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
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
