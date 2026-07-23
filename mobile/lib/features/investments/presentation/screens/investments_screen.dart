import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/investment_model.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  List<InvestmentModel> _investments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await AppServices.instance.investments.getAll();
      if (mounted) setState(() => _investments = data);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete(InvestmentModel inv) async {
    try {
      await AppServices.instance.investments.delete(inv.id);
      setState(() => _investments.remove(inv));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _openAddSheet() async {
    final added = await showModalBottomSheet<InvestmentModel>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddInvestmentSheet(),
    );
    if (added != null) {
      setState(() => _investments.insert(0, added));
      await UserPrefsStorage.addAchievement('portfolio_started');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investments'),
        actions: [
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _buildError()
                : _investments.isEmpty
                    ? _buildEmpty()
                    : _buildList(currency),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add investment'),
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );

  Widget _buildEmpty() => ListView(children: [
        const SizedBox(height: 100),
        const Icon(Icons.trending_up_rounded, size: 56, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        const Text('No investments yet', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Track your mutual funds, stocks, FDs, gold, PPF, and more in one place.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: ElevatedButton(onPressed: _openAddSheet, child: const Text('Add first investment')),
        ),
      ]);

  Widget _buildList(NumberFormat currency) {
    final totalInvested = _investments.fold(0.0, (s, i) => s + i.investedAmount);
    final totalCurrent = _investments.fold(0.0, (s, i) => s + i.currentValue);
    final totalReturns = totalCurrent - totalInvested;
    final totalReturnsPercent = totalInvested > 0 ? (totalReturns / totalInvested * 100) : 0.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _PortfolioSummaryCard(
          totalInvested: totalInvested,
          totalCurrent: totalCurrent,
          totalReturns: totalReturns,
          totalReturnsPercent: totalReturnsPercent,
          currency: currency,
        ),
        const SizedBox(height: 16),
        const Text('Your Holdings',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        ..._investments.map((inv) => _InvestmentCard(
              inv: inv,
              currency: currency,
              onDelete: () => _delete(inv),
            )),
      ],
    );
  }
}

class _PortfolioSummaryCard extends StatelessWidget {
  const _PortfolioSummaryCard({
    required this.totalInvested,
    required this.totalCurrent,
    required this.totalReturns,
    required this.totalReturnsPercent,
    required this.currency,
  });

  final double totalInvested, totalCurrent, totalReturns, totalReturnsPercent;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final isPositive = totalReturns >= 0;
    final color = isPositive ? AppColors.success : AppColors.danger;

    return Card(
      color: AppColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Portfolio Value',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(currency.format(totalCurrent),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 26)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _SummaryTile(
                label: 'Invested',
                value: currency.format(totalInvested),
                color: Colors.white70,
              ),
            ),
            Expanded(
              child: _SummaryTile(
                label: 'Returns',
                value: '${isPositive ? '+' : ''}${currency.format(totalReturns)} '
                    '(${totalReturnsPercent.toStringAsFixed(1)}%)',
                color: color,
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.color});
  final String label, value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
      ]);
}

class _InvestmentCard extends StatelessWidget {
  const _InvestmentCard({required this.inv, required this.currency, required this.onDelete});
  final InvestmentModel inv;
  final NumberFormat currency;
  final VoidCallback onDelete;

  static const _typeIcons = {
    'mutual_fund': '📊', 'stock': '📈', 'etf': '🏦', 'gold': '🥇',
    'fd': '🔒', 'ppf': '🛡️', 'nps': '🌱', 'bond': '📋', 'reit': '🏢', 'sip': '🔄',
  };

  @override
  Widget build(BuildContext context) {
    final icon = _typeIcons[inv.instrumentType.toLowerCase()] ?? '💰';
    final color = inv.isPositive ? AppColors.success : AppColors.danger;

    return Dismissible(
      key: Key(inv.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.danger,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async => await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Remove investment?'),
          content: Text('Remove "${inv.name}" from your portfolio?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove', style: TextStyle(color: AppColors.danger))),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(inv.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(inv.instrumentType.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(children: [
                  Text('Invested: ${currency.format(inv.investedAmount)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(currency.format(inv.currentValue),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                '${inv.isPositive ? '+' : ''}${inv.returnsPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: color, fontSize: 12),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Add Investment Sheet ────────────────────────────────────────────────────

class _AddInvestmentSheet extends StatefulWidget {
  const _AddInvestmentSheet();

  @override
  State<_AddInvestmentSheet> createState() => _AddInvestmentSheetState();
}

class _AddInvestmentSheetState extends State<_AddInvestmentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _investedController = TextEditingController();
  final _currentController = TextEditingController();
  String _instrumentType = 'mutual_fund';
  DateTime? _startedOn;
  bool _isSaving = false;

  static const _types = [
    ('mutual_fund', '📊', 'Mutual Fund'),
    ('sip', '🔄', 'SIP'),
    ('stock', '📈', 'Stock'),
    ('etf', '🏦', 'ETF'),
    ('gold', '🥇', 'Gold'),
    ('fd', '🔒', 'FD'),
    ('ppf', '🛡️', 'PPF'),
    ('nps', '🌱', 'NPS'),
    ('bond', '📋', 'Bond'),
    ('reit', '🏢', 'REIT'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _investedController.dispose();
    _currentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedOn ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startedOn = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final inv = await AppServices.instance.investments.create(
        instrumentType: _instrumentType,
        name: _nameController.text.trim(),
        investedAmount: double.parse(_investedController.text.trim()),
        currentValue: _currentController.text.trim().isNotEmpty
            ? double.parse(_currentController.text.trim())
            : null,
        startedOn: _startedOn,
      );
      if (mounted) Navigator.of(context).pop(inv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Add Investment', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ]),
            const SizedBox(height: 8),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 6,
              children: _types.map((t) {
                final (value, emoji, label) = t;
                final selected = _instrumentType == value;
                return FilterChip(
                  label: Text('$emoji $label'),
                  selected: selected,
                  onSelected: (_) => setState(() => _instrumentType = value),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Fund / Stock name',
                hintText: 'e.g. Axis Bluechip, Reliance Industries',
                prefixIcon: Icon(Icons.label_outline_rounded),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _investedController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Amount invested',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.currency_rupee_rounded),
              ),
              validator: (v) => (v == null || double.tryParse(v.trim()) == null) ? 'Enter a valid amount' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Current value (optional)',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.auto_graph_rounded),
                helperText: 'Leave blank to use invested amount',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start date (optional)',
                  prefixIcon: Icon(Icons.event_outlined),
                  suffixIcon: Icon(Icons.chevron_right),
                ),
                child: Text(_startedOn != null
                    ? DateFormat.yMMMd().format(_startedOn!)
                    : 'Select date'),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add to Portfolio'),
            ),
          ]),
        ),
      ),
    );
  }
}
