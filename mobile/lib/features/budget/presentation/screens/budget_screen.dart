import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/budget_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../features/transactions/domain/entities/transaction_entity.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _accentForCategory(String name) {
  final n = name.toLowerCase();
  if (n.contains('food') || n.contains('dining') || n.contains('restaurant')) {
    return const Color(0xFFF4722B);
  }
  if (n.contains('transport') || n.contains('travel') || n.contains('fuel')) {
    return const Color(0xFF1565C0);
  }
  if (n.contains('shop') || n.contains('cloth') || n.contains('fashion')) {
    return const Color(0xFF9C27B0);
  }
  if (n.contains('bill') || n.contains('util') || n.contains('electric') ||
      n.contains('phone') || n.contains('internet')) {
    return const Color(0xFF00695C);
  }
  if (n.contains('health') || n.contains('medical') || n.contains('pharma')) {
    return const Color(0xFF2E7D32);
  }
  if (n.contains('entertain') || n.contains('subscri') || n.contains('stream')) {
    return const Color(0xFFE91E63);
  }
  if (n.contains('invest') || n.contains('sip') || n.contains('mutual')) {
    return const Color(0xFF0F9D58);
  }
  if (n.contains('edu') || n.contains('course') || n.contains('book')) {
    return const Color(0xFF0288D1);
  }
  return const Color(0xFF5C6BC0);
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen>
    with SingleTickerProviderStateMixin {
  List<BudgetModel> _budgets = [];
  List<_UnbudgetedCategory> _unbudgeted = [];
  bool _isLoading = true;
  String? _error;
  late AnimationController _animCtrl;
  late Animation<double> _barAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _barAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    _animCtrl.reset();
    try {
      final results = await Future.wait([
        AppServices.instance.budgets.getCurrentPeriod(),
        AppServices.instance.transactions.getAll(direction: 'DEBIT'),
      ]);

      final budgets = results[0] as List<BudgetModel>;
      final txns = results[1] as List<TransactionEntity>;
      final unbudgeted = _computeUnbudgeted(budgets, txns);

      if (mounted) {
        setState(() {
          _budgets = budgets;
          _unbudgeted = unbudgeted;
        });
        _animCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_UnbudgetedCategory> _computeUnbudgeted(
    List<BudgetModel> budgets,
    List<TransactionEntity> txns,
  ) {
    final now = DateTime.now();
    final budgetedCategoryIds = budgets.map((b) => b.categoryId).toSet();
    final spendMap = <String, _UnbudgetedCategory>{};

    for (final t in txns) {
      if (t.transactionDate.year != now.year ||
          t.transactionDate.month != now.month) { continue; }
      if (t.categoryId == null) { continue; }
      if (budgetedCategoryIds.contains(t.categoryId)) { continue; }

      final key = t.categoryId!;
      if (!spendMap.containsKey(key)) {
        spendMap[key] = _UnbudgetedCategory(
          categoryId: key,
          categoryName: t.categoryName,
          spent: 0,
        );
      }
      spendMap[key] = _UnbudgetedCategory(
        categoryId: key,
        categoryName: t.categoryName,
        spent: spendMap[key]!.spent + t.amount,
      );
    }

    final list = spendMap.values.toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));
    return list;
  }

  void _openAddSheet({String? prefillCategoryId, String? prefillCategoryName}) async {
    final usedCategoryIds = _budgets.map((b) => b.categoryId).toSet();
    final added = await showModalBottomSheet<BudgetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(
        usedCategoryIds: usedCategoryIds,
        prefillCategoryId: prefillCategoryId,
        prefillCategoryName: prefillCategoryName,
      ),
    );
    if (added != null) {
      setState(() {
        _budgets.add(added);
        _unbudgeted.removeWhere((u) => u.categoryId == added.categoryId);
      });
      _animCtrl.reset();
      _animCtrl.forward();
    }
  }

  void _openEditSheet(BudgetModel budget) async {
    final updated = await showModalBottomSheet<BudgetModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBudgetSheet(budget: budget),
    );
    if (updated != null) {
      setState(() {
        final i = _budgets.indexWhere((b) => b.id == updated.id);
        if (i >= 0) _budgets[i] = updated;
      });
      _animCtrl.reset();
      _animCtrl.forward();
    }
  }

  Future<void> _deleteBudget(BudgetModel budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove budget?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        content: Text(
          '${budget.categoryIcon} ${budget.categoryName} budget will be removed for this month.',
          style: GoogleFonts.dmSans(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Remove',
                style: GoogleFonts.dmSans(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await AppServices.instance.budgets.delete(budget.id);
      setState(() => _budgets.removeWhere((b) => b.id == budget.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Budget',
          style: GoogleFonts.manrope(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: AppColors.textSecondary,
              onPressed: _load,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Set Budget',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: Text('Retry', style: GoogleFonts.dmSans()),
              ),
            ],
          ),
        ),
      );
    }
    if (_budgets.isEmpty && _unbudgeted.isEmpty) {
      return _EmptyState(onAdd: _openAddSheet);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        if (_budgets.isNotEmpty) ...[
          _BudgetSummaryCard(budgets: _budgets, barAnim: _barAnim),
          const SizedBox(height: 24),
          Text(
            'Your Budgets',
            style: GoogleFonts.manrope(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          ..._budgets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(b.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_rounded,
                          color: Colors.white, size: 22),
                      SizedBox(height: 4),
                      Text('Remove',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  await _deleteBudget(b);
                  return false;
                },
                child: _BudgetCard(
                  budget: b,
                  barAnim: _barAnim,
                  onEdit: () => _openEditSheet(b),
                ),
              ),
            ),
          ),
        ],

        // Unbudgeted spending
        if (_unbudgeted.isNotEmpty) ...[
          const SizedBox(height: 16),
          _UnbudgetedSection(
            categories: _unbudgeted,
            onSetLimit: (u) => _openAddSheet(
              prefillCategoryId: u.categoryId,
              prefillCategoryName: u.categoryName,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Budget Summary Card ───────────────────────────────────────────────────────

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.budgets,
    required this.barAnim,
  });
  final List<BudgetModel> budgets;
  final Animation<double> barAnim;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final totalLimit = budgets.fold(0.0, (s, b) => s + b.monthlyLimit);
    final totalSpent = budgets.fold(0.0, (s, b) => s + b.spent);
    final frac = totalLimit > 0 ? (totalSpent / totalLimit).clamp(0.0, 1.0) : 0.0;
    final overCount = budgets.where((b) => b.overBudget).length;
    final onTrack = budgets.length - overCount;
    final now = DateTime.now();
    final monthLabel =
        DateFormat('MMMM yyyy').format(now);

    final barColor = frac > 0.9
        ? AppColors.danger
        : frac > 0.75
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                monthLabel,
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (overCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '$overCount over limit',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 11, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        'All on track',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currency.format(totalSpent),
                    style: GoogleFonts.manrope(
                      color: barColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'of ${currency.format(totalLimit)} budgeted',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Mini donut
              _MiniDonut(fraction: frac, color: barColor),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          AnimatedBuilder(
            animation: barAnim,
            builder: (_, __) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: (frac * barAnim.value).clamp(0.0, 1.0),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatPill(
                label: 'Remaining',
                value: currency.format(max(0, totalLimit - totalSpent)),
                color: AppColors.success,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'On track',
                value: '$onTrack of ${budgets.length}',
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              _StatPill(
                label: 'Used',
                value: '${(frac * 100).toStringAsFixed(0)}%',
                color: barColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDonut extends StatelessWidget {
  const _MiniDonut({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _DonutPainter(fraction: fraction, color: color),
        child: Center(
          child: Text(
            '${(fraction * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - 8) / 2;
    final paint = Paint()
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
        center, radius, paint..color = color.withValues(alpha: 0.12));
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * fraction.clamp(0.0, 1.0),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.fraction != fraction;
}

class _StatPill extends StatelessWidget {
  const _StatPill(
      {required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-Category Budget Card ──────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.barAnim,
    required this.onEdit,
  });
  final BudgetModel budget;
  final Animation<double> barAnim;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final f = budget.progressFraction;
    final accent = _accentForCategory(budget.categoryName);
    final barColor = budget.overBudget
        ? AppColors.danger
        : f > 0.8
            ? AppColors.warning
            : AppColors.success;

    return GestureDetector(
      onTap: onEdit,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: budget.overBudget
                ? AppColors.danger.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Left accent strip
            Container(
              width: 4,
              height: 88,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Emoji
            Text(budget.categoryIcon,
                style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            budget.categoryName,
                            style: GoogleFonts.manrope(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (budget.overBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'OVER',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: barAnim,
                      builder: (_, __) {
                        return Stack(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor:
                                  (f * barAnim.value).clamp(0.0, 1.0),
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: barColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          currency.format(budget.spent),
                          style: GoogleFonts.manrope(
                            color: barColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          ' / ${currency.format(budget.monthlyLimit)}',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          budget.overBudget
                              ? '${currency.format(budget.spent - budget.monthlyLimit)} over'
                              : '${currency.format(budget.remainingAmount)} left',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: budget.overBudget
                                ? AppColors.danger
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Edit hint
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(
                Icons.edit_rounded,
                size: 15,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Unbudgeted Spending Section ───────────────────────────────────────────────

class _UnbudgetedCategory {
  const _UnbudgetedCategory({
    required this.categoryId,
    required this.categoryName,
    required this.spent,
  });
  final String categoryId;
  final String categoryName;
  final double spent;
}

class _UnbudgetedSection extends StatelessWidget {
  const _UnbudgetedSection({
    required this.categories,
    required this.onSetLimit,
  });
  final List<_UnbudgetedCategory> categories;
  final void Function(_UnbudgetedCategory) onSetLimit;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Spending Without Limits',
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25)),
              ),
              child: Text(
                '${categories.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'You\'re spending here this month with no budget set.',
          style: GoogleFonts.dmSans(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ...categories.map(
          (u) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _accentForCategory(u.categoryName)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      _categoryEmoji(u.categoryName),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.categoryName,
                        style: GoogleFonts.manrope(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${currency.format(u.spent)} spent this month',
                        style: GoogleFonts.dmSans(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => onSetLimit(u),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      '+ Set limit',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _categoryEmoji(String name) {
    final n = name.toLowerCase();
    if (n.contains('food') || n.contains('dining')) return '🍔';
    if (n.contains('transport') || n.contains('travel')) return '🚗';
    if (n.contains('shop') || n.contains('cloth')) return '🛍';
    if (n.contains('bill') || n.contains('util')) return '💡';
    if (n.contains('health') || n.contains('medical')) return '🏥';
    if (n.contains('entertain') || n.contains('subscri')) return '🎬';
    if (n.contains('invest') || n.contains('sip')) return '📈';
    if (n.contains('edu') || n.contains('course')) return '📚';
    return '💸';
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pie_chart_outline_rounded,
              size: 38,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'No budgets set yet',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Set monthly limits per category. PennyWise will track actual spending and alert you before you overspend.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton(
            onPressed: onAdd,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              'Set my first budget',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Add Budget Sheet ──────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({
    required this.usedCategoryIds,
    this.prefillCategoryId,
    this.prefillCategoryName,
  });
  final Set<String> usedCategoryIds;
  final String? prefillCategoryId;
  final String? prefillCategoryName;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.prefillCategoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final all = await AppServices.instance.categories.getAll();
      if (mounted) {
        setState(() => _categories = all
            .where((c) =>
                c.type == 'EXPENSE' &&
                !widget.usedCategoryIds.contains(c.id))
            .toList());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final budget = await AppServices.instance.budgets.create(
        categoryId: _selectedCategoryId!,
        monthlyLimit: double.parse(_limitController.text.trim()),
      );
      if (mounted) Navigator.of(context).pop(budget);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Set Budget',
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Set a monthly spending limit for a category.',
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            if (_categories.isEmpty && _selectedCategoryId == null)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Category',
                  labelStyle:
                      GoogleFonts.dmSans(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.category_outlined,
                      color: AppColors.textSecondary, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icon}  ${c.name}',
                              style: GoogleFonts.dmSans()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
                validator: (v) =>
                    v == null ? 'Select a category' : null,
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w600, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Monthly limit',
                labelStyle:
                    GoogleFonts.dmSans(color: AppColors.textSecondary),
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
                prefixIcon: const Icon(Icons.currency_rupee_rounded,
                    color: AppColors.textSecondary, size: 20),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (v) =>
                  (v == null || double.tryParse(v.trim()) == null)
                      ? 'Enter a valid amount'
                      : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Save Budget',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Edit Budget Sheet ─────────────────────────────────────────────────────────

class _EditBudgetSheet extends StatefulWidget {
  const _EditBudgetSheet({required this.budget});
  final BudgetModel budget;

  @override
  State<_EditBudgetSheet> createState() => _EditBudgetSheetState();
}

class _EditBudgetSheetState extends State<_EditBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _limitController = TextEditingController(
      text: widget.budget.monthlyLimit.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final newLimit = double.parse(_limitController.text.trim());
    setState(() => _isSaving = true);
    try {
      final updated = await AppServices.instance.budgets
          .update(widget.budget.id, monthlyLimit: newLimit);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(friendlyError(e)),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForCategory(widget.budget.categoryName);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(widget.budget.categoryIcon,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Budget',
                      style: GoogleFonts.manrope(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      widget.budget.categoryName,
                      style: GoogleFonts.dmSans(
                        color: accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _limitController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700, fontSize: 22),
              decoration: InputDecoration(
                labelText: 'New monthly limit',
                labelStyle:
                    GoogleFonts.dmSans(color: AppColors.textSecondary),
                prefixText: '₹ ',
                prefixStyle: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: AppColors.textPrimary),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: accent, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              validator: (v) =>
                  (v == null || double.tryParse(v.trim()) == null)
                      ? 'Enter a valid amount'
                      : null,
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Update Limit',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
