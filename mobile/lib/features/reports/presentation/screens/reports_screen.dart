import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isLoading = true;
  String? _error;
  List<TransactionEntity> _txs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final txs = await AppServices.instance.transactions.getAll();
      if (mounted) setState(() => _txs = txs);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Build last-6-months spend map: { "Jul 26": 12000, ... }
  Map<String, double> _monthlySpend() {
    final now = DateTime.now();
    final result = <String, double>{};
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      result[DateFormat('MMM yy').format(m)] = 0.0;
    }
    for (final tx in _txs) {
      if (tx.direction != 'DEBIT') continue;
      final key = DateFormat('MMM yy').format(tx.transactionDate);
      if (result.containsKey(key)) {
        result[key] = (result[key] ?? 0) + tx.amount;
      }
    }
    return result;
  }

  Map<String, double> _categorySpend() {
    final map = <String, double>{};
    for (final tx in _txs) {
      if (tx.direction != 'DEBIT') continue;
      final cat =
          tx.categoryName.isEmpty ? 'Uncategorized' : tx.categoryName;
      map[cat] = (map[cat] ?? 0) + tx.amount;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(5));
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _txs.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Icon(Icons.bar_chart_rounded,
                                size: 56, color: AppColors.textSecondary),
                            SizedBox(height: 16),
                            Text(
                              'No transactions yet',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 48),
                              child: Text(
                                'Add transactions to see your spending reports.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        )
                      : _buildContent(currency),
                ),
    );
  }

  Widget _buildContent(NumberFormat currency) {
    final monthly = _monthlySpend();
    final cats = _categorySpend();
    final totalSpend = _txs
        .where((t) => t.direction == 'DEBIT')
        .fold(0.0, (s, t) => s + t.amount);
    final debitTxs = _txs.where((t) => t.direction == 'DEBIT').length;
    final months = monthly.values.where((v) => v > 0);
    final avgMonthly =
        months.isEmpty ? 0.0 : months.reduce((a, b) => a + b) / months.length;
    final maxMonth =
        months.isEmpty ? 0.0 : months.reduce((a, b) => a > b ? a : b);

    final barValues = monthly.values.toList();
    final barMax = barValues.isEmpty
        ? 1.0
        : (barValues.reduce((a, b) => a > b ? a : b) * 1.2)
            .clamp(1.0, double.infinity);
    final catTotal = cats.values.fold(0.0, (s, v) => s + v);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Stats row
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Spent',
                value: currency.format(totalSpend),
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Avg / Month',
                value: currency.format(avgMonthly),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Transactions',
                value: '$debitTxs',
                color: AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Bar chart
        const Text('Monthly Spending',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
            child: SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: barMax,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.15),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final keys = monthly.keys.toList();
                          final idx = v.toInt();
                          if (idx < 0 || idx >= keys.length) {
                            return const SizedBox();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              keys[idx],
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: barValues
                      .asMap()
                      .entries
                      .map(
                        (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value,
                              color: e.value == maxMonth && maxMonth > 0
                                  ? AppColors.danger
                                  : AppColors.primary,
                              width: 22,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4)),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                        currency.format(rod.toY),
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Category breakdown
        if (cats.isNotEmpty) ...[
          const Text('Top Categories',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: cats.entries.map((e) {
                  final frac = catTotal > 0
                      ? (e.value / catTotal).clamp(0.0, 1.0)
                      : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${currency.format(e.value)} · ${(frac * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: frac,
                            minHeight: 7,
                            backgroundColor: AppColors.background,
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 14, color: color),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
