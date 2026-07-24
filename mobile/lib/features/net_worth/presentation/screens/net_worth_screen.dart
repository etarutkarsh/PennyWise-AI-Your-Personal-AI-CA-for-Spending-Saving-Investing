import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/net_worth_repository.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  NetWorthSummary? _summary;
  bool _isLoading = true;
  String? _error;

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
      final summary = await AppServices.instance.netWorth.getSummary();
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAsset(String id) async {
    try {
      await AppServices.instance.netWorth.deleteAsset(id);
      await _load();
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

  Future<void> _deleteLiability(String id) async {
    try {
      await AppServices.instance.netWorth.deleteLiability(id);
      await _load();
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

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddItemSheet(
        onAssetAdded: (type, name, value) async {
          Navigator.pop(ctx);
          try {
            await AppServices.instance.netWorth
                .createAsset(assetType: type, name: name, value: value);
            await _load();
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
        },
        onLiabilityAdded:
            (type, name, outstanding, monthlyEmi, interestRate) async {
          Navigator.pop(ctx);
          try {
            await AppServices.instance.netWorth.createLiability(
              liabilityType: type,
              name: name,
              outstanding: outstanding,
              monthlyEmi: monthlyEmi,
              interestRate: interestRate,
            );
            await _load();
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Net Worth'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label:
            const Text('Add Item', style: TextStyle(color: Colors.white)),
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
                        Text(_error!, textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    children: [
                      // Summary card
                      _SummaryCard(summary: _summary!, currency: currency),
                      const SizedBox(height: 20),

                      // Assets section
                      Row(
                        children: [
                          const Icon(Icons.trending_up_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Assets',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            currency.format(_summary!.totalAssets),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_summary!.assets.isEmpty)
                        _EmptyHint(
                          message: 'No assets yet. Tap + to add property, gold, or cash.',
                          color: AppColors.primary,
                        )
                      else
                        ...(_summary!.assets.map(
                          (a) => _SwipeToDeleteCard(
                            key: ValueKey('asset_${a.id}'),
                            onDelete: () => _deleteAsset(a.id),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.12),
                                child: Text(
                                  _assetEmoji(a.assetType),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              title: Text(a.name.isNotEmpty
                                  ? a.name
                                  : _assetLabel(a.assetType)),
                              subtitle: Text(_assetLabel(a.assetType),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                              trailing: Text(
                                currency.format(a.value),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        )),
                      const SizedBox(height: 20),

                      // Liabilities section
                      Row(
                        children: [
                          const Icon(Icons.trending_down_rounded,
                              color: AppColors.danger, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Liabilities',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            currency.format(_summary!.totalLiabilities),
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_summary!.liabilities.isEmpty)
                        _EmptyHint(
                          message: 'No liabilities. Tap + to add loans or credit card dues.',
                          color: AppColors.danger,
                        )
                      else
                        ...(_summary!.liabilities.map(
                          (l) => _SwipeToDeleteCard(
                            key: ValueKey('liab_${l.id}'),
                            onDelete: () => _deleteLiability(l.id),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.danger.withValues(alpha: 0.12),
                                child: Text(
                                  _liabilityEmoji(l.liabilityType),
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ),
                              title: Text(l.name.isNotEmpty
                                  ? l.name
                                  : _liabilityLabel(l.liabilityType)),
                              subtitle: Text(
                                _liabilityLabel(l.liabilityType) +
                                    (l.monthlyEmi != null
                                        ? ' · EMI ${currency.format(l.monthlyEmi)}'
                                        : ''),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                              trailing: Text(
                                currency.format(l.outstanding),
                                style: const TextStyle(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
                ),
    );
  }

  String _assetEmoji(String type) {
    switch (type) {
      case 'real_estate':
        return '🏠';
      case 'vehicle':
        return '🚗';
      case 'cash':
        return '💰';
      case 'investments':
        return '📈';
      case 'fd_rd':
        return '🏦';
      case 'gold':
        return '💎';
      default:
        return '💼';
    }
  }

  String _assetLabel(String type) {
    switch (type) {
      case 'real_estate':
        return 'Property';
      case 'vehicle':
        return 'Vehicle';
      case 'cash':
        return 'Cash';
      case 'investments':
        return 'Investments';
      case 'fd_rd':
        return 'FD / RD';
      case 'gold':
        return 'Gold';
      default:
        return 'Other';
    }
  }

  String _liabilityEmoji(String type) {
    switch (type) {
      case 'home_loan':
        return '🏦';
      case 'car_loan':
        return '🚗';
      case 'credit_card':
        return '💳';
      case 'education_loan':
        return '📚';
      case 'personal_loan':
        return '💊';
      default:
        return '📋';
    }
  }

  String _liabilityLabel(String type) {
    switch (type) {
      case 'home_loan':
        return 'Home Loan';
      case 'car_loan':
        return 'Car Loan';
      case 'credit_card':
        return 'Credit Card';
      case 'education_loan':
        return 'Education Loan';
      case 'personal_loan':
        return 'Personal Loan';
      default:
        return 'Other';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.summary, required this.currency});

  final NetWorthSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netWorth >= 0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Net Worth',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(summary.netWorth),
            style: TextStyle(
              color: isPositive ? AppColors.success : AppColors.danger,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Assets',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(summary.totalAssets),
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Liabilities',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(summary.totalLiabilities),
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SwipeToDeleteCard extends StatelessWidget {
  const _SwipeToDeleteCard({
    super.key,
    required this.child,
    required this.onDelete,
  });

  final Widget child;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: key!,
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete?'),
            content: const Text('This will permanently remove this entry.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(child: child),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ── Add item bottom sheet ─────────────────────────────────────────────────────

typedef _AssetAdded = void Function(String type, String name, double value);
typedef _LiabilityAdded = void Function(
    String type, String name, double outstanding, double? emi, double? rate);

class _AddItemSheet extends StatefulWidget {
  const _AddItemSheet({
    required this.onAssetAdded,
    required this.onLiabilityAdded,
  });

  final _AssetAdded onAssetAdded;
  final _LiabilityAdded onLiabilityAdded;

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  bool _isAsset = true;

  // Asset type chips
  static const _assetTypes = [
    ('real_estate', '🏠 Property'),
    ('vehicle', '🚗 Vehicle'),
    ('cash', '💰 Cash'),
    ('investments', '📈 Investments'),
    ('fd_rd', '🏦 FD/RD'),
    ('gold', '💎 Gold'),
  ];

  // Liability type chips
  static const _liabilityTypes = [
    ('home_loan', '🏦 Home Loan'),
    ('car_loan', '🚗 Car Loan'),
    ('credit_card', '💳 Credit Card'),
    ('education_loan', '📚 Education Loan'),
    ('personal_loan', '💊 Personal Loan'),
  ];

  String? _selectedType;
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _emiCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _emiCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a type')),
      );
      return;
    }
    final name = _nameCtrl.text.trim();
    final valueText = _valueCtrl.text.trim();
    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_isAsset) {
      widget.onAssetAdded(_selectedType!, name, value);
    } else {
      final emi = double.tryParse(_emiCtrl.text.trim());
      final rate = double.tryParse(_rateCtrl.text.trim());
      widget.onLiabilityAdded(_selectedType!, name, value, emi, rate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _isAsset ? _assetTypes : _liabilityTypes;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Net Worth Item',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Asset / Liability toggle
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Asset'),
                    selected: _isAsset,
                    onSelected: (_) => setState(() {
                      _isAsset = true;
                      _selectedType = null;
                    }),
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Liability'),
                    selected: !_isAsset,
                    onSelected: (_) => setState(() {
                      _isAsset = false;
                      _selectedType = null;
                    }),
                    selectedColor: AppColors.danger.withValues(alpha: 0.2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type chips
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: types
                  .map((t) => ChoiceChip(
                        label: Text(t.$2, style: const TextStyle(fontSize: 12)),
                        selected: _selectedType == t.$1,
                        onSelected: (_) =>
                            setState(() => _selectedType = t.$1),
                        selectedColor: (_isAsset ? AppColors.primary : AppColors.danger)
                            .withValues(alpha: 0.2),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Name
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: _isAsset ? 'Name (e.g. Flat in Pune)' : 'Name (e.g. SBI Home Loan)',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Value / Outstanding
            TextField(
              controller: _valueCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _isAsset ? 'Current Value (₹)' : 'Outstanding Amount (₹)',
                prefixText: '₹ ',
                border: const OutlineInputBorder(),
              ),
            ),

            // Liability-specific fields
            if (!_isAsset) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _emiCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly EMI (₹) — optional',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Interest Rate (%) — optional',
                  suffixText: '%',
                  border: OutlineInputBorder(),
                ),
              ),
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isAsset ? AppColors.primary : AppColors.danger,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submit,
                child: Text(_isAsset ? 'Add Asset' : 'Add Liability'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
