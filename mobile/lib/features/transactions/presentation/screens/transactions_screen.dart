import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import 'add_transaction_sheet.dart';

// ---------------------------------------------------------------------------
// Period filter
// ---------------------------------------------------------------------------
enum _Period { today, week, twoWeeks, month, sixMonths, all }

const _periodLabels = {
  _Period.today: 'Today',
  _Period.week: '7 Days',
  _Period.twoWeeks: '2 Weeks',
  _Period.month: 'Month',
  _Period.sixMonths: '6 Months',
  _Period.all: 'All',
};

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<TransactionEntity> _transactions = [];
  bool _loading = true;
  String? _error;

  _Period _period = _Period.all;

  static final _dateFmt = DateFormat('dd MMM');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final txns = await AppServices.instance.transactions.getAll();
      if (mounted) setState(() { _transactions = txns; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = friendlyError(e); _loading = false; });
    }
  }

  void _showAddTransaction() async {
    final tx = await showModalBottomSheet<TransactionEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AddTransactionSheet(),
    );
    if (tx != null && mounted) {
      setState(() => _transactions.insert(0, tx));
    }
  }

  // -------------------------------------------------------------------------
  // Filtered list + computed stats
  // -------------------------------------------------------------------------
  List<TransactionEntity> get _filtered {
    if (_period == _Period.all) return _transactions;
    final now = DateTime.now();
    final cutoff = switch (_period) {
      _Period.today => DateTime(now.year, now.month, now.day),
      _Period.week => now.subtract(const Duration(days: 7)),
      _Period.twoWeeks => now.subtract(const Duration(days: 14)),
      _Period.month => DateTime(now.year, now.month - 1, now.day),
      _Period.sixMonths => DateTime(now.year, now.month - 6, now.day),
      _Period.all => DateTime(2000),
    };
    return _transactions
        .where((t) => !t.transactionDate.isBefore(cutoff))
        .toList();
  }

  double get _periodSpent => _filtered
      .where((t) => t.direction == 'DEBIT')
      .fold(0.0, (s, t) => s + t.amount);

  double get _periodIncome => _filtered
      .where((t) => t.direction == 'CREDIT')
      .fold(0.0, (s, t) => s + t.amount);

  Map<String, List<TransactionEntity>> get _grouped {
    final m = <String, List<TransactionEntity>>{};
    for (final t in _filtered) {
      final key = _dateFmt.format(t.transactionDate);
      m.putIfAbsent(key, () => []).add(t);
    }
    return m;
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;
    final days = grouped.keys.toList();
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: AppColors.surface,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          Text('${_filtered.length} transactions',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/sms-import'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sms_outlined,
                                  color: AppColors.orange, size: 16),
                              const SizedBox(width: 6),
                              Text('SMS',
                                  style: GoogleFonts.dmSans(
                                      color: AppColors.textPrimary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddTransaction,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // Period filter chips + summary stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _Period.values.map((p) {
                            final selected = _period == p;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_periodLabels[p]!),
                                selected: selected,
                                onSelected: (_) =>
                                    setState(() => _period = p),
                                selectedColor:
                                    AppColors.orange.withValues(alpha: 0.15),
                                checkmarkColor: AppColors.orange,
                                side: BorderSide(
                                  color: selected
                                      ? AppColors.orange
                                          .withValues(alpha: 0.4)
                                      : AppColors.border,
                                ),
                                backgroundColor: AppColors.surface,
                                labelStyle: GoogleFonts.dmSans(
                                  color: selected
                                      ? AppColors.orange
                                      : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 0),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (!_loading && _transactions.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatPill(
                              label: 'Spent',
                              value: currency.format(_periodSpent),
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 10),
                            _StatPill(
                              label: 'Income',
                              value: currency.format(_periodIncome),
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 10),
                            _StatPill(
                              label: 'Net',
                              value: currency
                                  .format(_periodIncome - _periodSpent),
                              color: (_periodIncome - _periodSpent) >= 0
                                  ? AppColors.primary
                                  : AppColors.danger,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // Content
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.orange)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_transactions.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.textSecondary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text('No activity yet',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('Log a transaction or import from SMS',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 14)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddTransaction,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Log Transaction'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_off_rounded,
                            color: AppColors.textSecondary, size: 40),
                        const SizedBox(height: 12),
                        Text('No transactions in this period',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, i) {
                      final day = days[i];
                      final txns = grouped[day]!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10, top: 4),
                            child: Text(day,
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                          ...txns.map((t) => _TxnCard(
                              txn: t,
                              onDelete: () async {
                                await AppServices.instance.transactions
                                    .delete(t.id);
                                _load();
                              })),
                          const SizedBox(height: 8),
                        ],
                      );
                    }, childCount: days.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _StatPill
// ---------------------------------------------------------------------------
class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TxnCard
// ---------------------------------------------------------------------------
class _TxnCard extends StatelessWidget {
  const _TxnCard({required this.txn, required this.onDelete});
  final TransactionEntity txn;
  final VoidCallback onDelete;

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  bool get _isDebit => txn.direction == 'DEBIT';

  Color get _amountColor => _isDebit ? AppColors.danger : AppColors.success;

  String get _letter =>
      txn.merchant.isNotEmpty ? txn.merchant[0].toUpperCase() : '?';

  Color get _letterBg =>
      _isDebit ? AppColors.questRose : AppColors.questGreen;

  Color get _letterColor =>
      _isDebit ? const Color(0xFFC62828) : const Color(0xFF0F9D58);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(txn.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.danger, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text('Delete?',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700)),
                content: Text('Remove this transaction?',
                    style:
                        GoogleFonts.dmSans(color: AppColors.textSecondary)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Cancel',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Delete',
                          style: GoogleFonts.dmSans(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700))),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: _letterBg,
                  borderRadius: BorderRadius.circular(13)),
              child: Center(
                child: Text(_letter,
                    style: GoogleFonts.dmSans(
                        color: _letterColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(txn.merchant,
                      style: GoogleFonts.dmSans(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(txn.categoryName,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary, fontSize: 11)),
                      const SizedBox(width: 6),
                      const Text('·',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 11)),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('HH:mm')
                            .format(txn.transactionDate.toLocal()),
                        style: GoogleFonts.dmSans(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${_isDebit ? '-' : '+'}${_currency.format(txn.amount)}',
              style: GoogleFonts.dmSans(
                color: _amountColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
