import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/transaction_entity.dart';
import 'add_transaction_sheet.dart';
import 'edit_transaction_sheet.dart';

// ---------------------------------------------------------------------------
// Direction filter
// ---------------------------------------------------------------------------
enum _DirectionFilter { all, income, expense }

const _directionLabels = {
  _DirectionFilter.all: 'All',
  _DirectionFilter.income: 'Income',
  _DirectionFilter.expense: 'Expense',
};

// ---------------------------------------------------------------------------
// Category color + emoji mapping
// ---------------------------------------------------------------------------
const _catColors = {
  'Food': Color(0xFFFF6B35),
  'Transport': Color(0xFF4ECDC4),
  'Shopping': Color(0xFF9B59B6),
  'Bills': Color(0xFFE74C3C),
  'Salary': Color(0xFF2ECC71),
  'Investment': Color(0xFF3498DB),
  'Health': Color(0xFFE91E63),
  'Entertainment': Color(0xFFFF9800),
  'Travel': Color(0xFF00BCD4),
  'Education': Color(0xFF8BC34A),
};

const _catEmojis = {
  'Food': '🍔',
  'Transport': '🚗',
  'Shopping': '🛍',
  'Bills': '💡',
  'Salary': '💰',
  'Investment': '📈',
  'Health': '🏥',
  'Entertainment': '🎬',
  'Travel': '✈',
  'Education': '📚',
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

  // Filter state
  _DirectionFilter _directionFilter = _DirectionFilter.all;
  bool _showSearch = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------------
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final direction = _directionFilter == _DirectionFilter.all
          ? null
          : _directionFilter == _DirectionFilter.income
              ? 'CREDIT'
              : 'DEBIT';
      final txns = await AppServices.instance.transactions.getAll(
        direction: direction,
      );
      if (mounted) setState(() { _transactions = txns; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = friendlyError(e); _loading = false; });
    }
  }

  void _onDirectionChanged(_DirectionFilter f) {
    setState(() => _directionFilter = f);
    _load();
  }

  // -------------------------------------------------------------------------
  // Client-side search filter
  // -------------------------------------------------------------------------
  List<TransactionEntity> get _filtered {
    if (_searchQuery.isEmpty) return _transactions;
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      return t.merchant.toLowerCase().contains(q) ||
          (t.note != null && t.note!.toLowerCase().contains(q)) ||
          t.categoryName.toLowerCase().contains(q);
    }).toList();
  }

  // -------------------------------------------------------------------------
  // Stats
  // -------------------------------------------------------------------------
  double get _totalSpent =>
      _filtered.where((t) => t.direction == 'DEBIT').fold(0.0, (s, t) => s + t.amount);

  double get _totalIncome =>
      _filtered.where((t) => t.direction == 'CREDIT').fold(0.0, (s, t) => s + t.amount);

  // -------------------------------------------------------------------------
  // Grouping
  // -------------------------------------------------------------------------
  Map<String, List<TransactionEntity>> _groupByDate(List<TransactionEntity> txns) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<TransactionEntity>>{};
    for (final t in txns) {
      final d = DateTime(t.transactionDate.year, t.transactionDate.month, t.transactionDate.day);
      String label;
      if (d == today) {
        label = 'Today';
      } else if (d == yesterday) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMMM d').format(d);
      }
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  // -------------------------------------------------------------------------
  // Insights
  // -------------------------------------------------------------------------
  List<_CategoryInsight> get _insights {
    final debitTxns = _filtered.where((t) => t.direction == 'DEBIT').toList();
    if (debitTxns.isEmpty) return [];
    final totals = <String, double>{};
    for (final t in debitTxns) {
      totals[t.categoryName] = (totals[t.categoryName] ?? 0) + t.amount;
    }
    final grand = totals.values.fold(0.0, (a, b) => a + b);
    if (grand == 0) return [];
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(4).map((e) => _CategoryInsight(
          name: e.key,
          amount: e.value,
          percent: e.value / grand,
        )).toList();
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------
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

  void _showEditTransaction(TransactionEntity txn) async {
    final updated = await showModalBottomSheet<TransactionEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => EditTransactionSheet(transaction: txn),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _transactions.indexWhere((t) => t.id == updated.id);
        if (idx != -1) _transactions[idx] = updated;
      });
    }
  }

  Future<void> _deleteTransaction(TransactionEntity txn) async {
    try {
      await AppServices.instance.transactions.delete(txn.id);
      if (mounted) {
        setState(() => _transactions.removeWhere((t) => t.id == txn.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final grouped = _groupByDate(filtered);
    final days = grouped.keys.toList();
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final insights = _insights;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: AppColors.surface,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              // ── AppBar ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transactions',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${filtered.length} records',
                            style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Search icon
                      _IconBtn(
                        icon: _showSearch
                            ? Icons.search_off_rounded
                            : Icons.search_rounded,
                        onTap: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (!_showSearch) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Add button
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

              // ── Search bar ───────────────────────────────────────────────
              if (_showSearch)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: GoogleFonts.dmSans(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search merchants, notes…',
                        hintStyle: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textSecondary, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: AppColors.textSecondary, size: 18),
                                onPressed: () => setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                }),
                              )
                            : null,
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.orange, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Direction filter chips ───────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _DirectionFilter.values.map((f) {
                        final selected = _directionFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_directionLabels[f]!),
                            selected: selected,
                            onSelected: (_) => _onDirectionChanged(f),
                            selectedColor:
                                AppColors.orange.withValues(alpha: 0.15),
                            checkmarkColor: AppColors.orange,
                            side: BorderSide(
                              color: selected
                                  ? AppColors.orange.withValues(alpha: 0.4)
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
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 14)),

              // ── Summary row ──────────────────────────────────────────────
              if (!_loading && _transactions.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _StatPill(
                          label: 'Spent',
                          value: currency.format(_totalSpent),
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        _StatPill(
                          label: 'Income',
                          value: currency.format(_totalIncome),
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        _StatPill(
                          label: 'Net',
                          value: currency.format(_totalIncome - _totalSpent),
                          color: (_totalIncome - _totalSpent) >= 0
                              ? AppColors.primary
                              : AppColors.danger,
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_loading && _transactions.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Insights ─────────────────────────────────────────────────
              if (!_loading && filtered.length >= 5 && insights.isNotEmpty)
                SliverToBoxAdapter(
                  child: _InsightsCard(
                    insights: insights,
                    currency: currency,
                  ),
                ),

              if (!_loading && filtered.length >= 5 && insights.isNotEmpty)
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // ── Content ──────────────────────────────────────────────────
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Could not load',
                          style: GoogleFonts.dmSans(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load,
                            child: const Text('Retry')),
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
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.receipt_long_outlined,
                              color: AppColors.textSecondary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No activity yet',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to log your first transaction',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
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
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list_off_rounded,
                            color: AppColors.textSecondary, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No transactions match',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final day = days[i];
                        final txns = grouped[day]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10, top: 4),
                              child: Text(
                                day,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            ...txns.map((t) => _TxnCard(
                                  txn: t,
                                  onEdit: () => _showEditTransaction(t),
                                  onDelete: () => _deleteTransaction(t),
                                )),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                      childCount: days.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransaction,
        backgroundColor: AppColors.orange,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _IconBtn
// ---------------------------------------------------------------------------
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
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
// _CategoryInsight data class
// ---------------------------------------------------------------------------
class _CategoryInsight {
  const _CategoryInsight({
    required this.name,
    required this.amount,
    required this.percent,
  });
  final String name;
  final double amount;
  final double percent;
}

// ---------------------------------------------------------------------------
// _InsightsCard
// ---------------------------------------------------------------------------
class _InsightsCard extends StatelessWidget {
  const _InsightsCard({
    required this.insights,
    required this.currency,
  });

  final List<_CategoryInsight> insights;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Financial Insights',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'This period',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...insights.map((ins) {
              final color = _catColors[ins.name] ?? AppColors.orange;
              final emoji = _catEmojis[ins.name] ?? '💸';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ins.name,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                currency.format(ins.amount),
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${(ins.percent * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ins.percent,
                              backgroundColor:
                                  color.withValues(alpha: 0.12),
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(color),
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TxnCard
// ---------------------------------------------------------------------------
class _TxnCard extends StatelessWidget {
  const _TxnCard({
    required this.txn,
    required this.onEdit,
    required this.onDelete,
  });

  final TransactionEntity txn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  bool get _isDebit => txn.direction == 'DEBIT';
  Color get _amountColor => _isDebit ? AppColors.danger : AppColors.success;
  Color get _circleColor =>
      (_catColors[txn.categoryName] ?? (_isDebit ? const Color(0xFFFF6B35) : AppColors.success))
          .withValues(alpha: 0.15);
  Color get _circleTextColor =>
      _catColors[txn.categoryName] ?? (_isDebit ? const Color(0xFFFF6B35) : AppColors.success);

  String get _circleContent {
    final emoji = _catEmojis[txn.categoryName];
    if (emoji != null) return emoji;
    return txn.merchant.isNotEmpty ? txn.merchant[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(txn.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child:
            const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 22),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                title: Text(
                  'Delete?',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                content: Text(
                  'Remove this transaction?',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      'Delete',
                      style: GoogleFonts.dmSans(
                        color: AppColors.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
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
              // Circle avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _circleColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _circleContent,
                    style: TextStyle(
                      color: _circleTextColor,
                      fontSize: _catEmojis.containsKey(txn.categoryName)
                          ? 20
                          : 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.merchant,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          txn.categoryName,
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        if (txn.paymentMethod != null) ...[
                          const SizedBox(width: 4),
                          const Text('·',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(width: 4),
                          Text(
                            txn.paymentMethod!,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        const Text('·',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 11)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('HH:mm')
                              .format(txn.transactionDate.toLocal()),
                          style: GoogleFonts.dmSans(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_isDebit ? '-' : '+'}${_currency.format(txn.amount)}',
                    style: GoogleFonts.dmSans(
                      color: _amountColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (txn.recurring)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'recurring',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
