import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    setState(() { _isLoading = true; _error = null; });
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
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
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
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
              );
            }
          }
        },
        onLiabilityAdded: (type, name, outstanding, monthlyEmi, interestRate) async {
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
                SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : _error != null
                ? _ErrorView(error: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.orange,
                    backgroundColor: AppColors.surface,
                    onRefresh: _load,
                    child: CustomScrollView(
                      slivers: [
                        // Header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.pop(),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                                        color: AppColors.textPrimary, size: 16),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Net Worth',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.textPrimary,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Assets minus what you owe',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _load,
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: const Icon(Icons.refresh_rounded,
                                        color: AppColors.textSecondary, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),

                        // Net Worth Hero Card
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _SummaryCard(
                                summary: _summary!, currency: currency),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),

                        // Assets header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.trending_up_rounded,
                                      color: AppColors.success, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Assets',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  currency.format(_summary!.totalAssets),
                                  style: GoogleFonts.manrope(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Assets list
                        if (_summary!.assets.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _EmptyHint(
                                message: 'No assets yet. Tap + to add property, gold, or investments.',
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _SwipeToDeleteCard(
                                  key: ValueKey('asset_${_summary!.assets[i].id}'),
                                  onDelete: () => _deleteAsset(_summary!.assets[i].id),
                                  child: _AssetRow(
                                    emoji: _assetEmoji(_summary!.assets[i].assetType),
                                    name: _summary!.assets[i].name.isNotEmpty
                                        ? _summary!.assets[i].name
                                        : _assetLabel(_summary!.assets[i].assetType),
                                    type: _assetLabel(_summary!.assets[i].assetType),
                                    value: currency.format(_summary!.assets[i].value),
                                    isAsset: true,
                                  ),
                                ),
                                childCount: _summary!.assets.length,
                              ),
                            ),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 28)),

                        // Liabilities header
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.danger.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.trending_down_rounded,
                                      color: AppColors.danger, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Liabilities',
                                  style: GoogleFonts.dmSans(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  currency.format(_summary!.totalLiabilities),
                                  style: GoogleFonts.manrope(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        // Liabilities list
                        if (_summary!.liabilities.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _EmptyHint(
                                message: 'No liabilities. Tap + to add loans or credit card dues.',
                                color: AppColors.danger,
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) => _SwipeToDeleteCard(
                                  key: ValueKey('liab_${_summary!.liabilities[i].id}'),
                                  onDelete: () => _deleteLiability(_summary!.liabilities[i].id),
                                  child: _AssetRow(
                                    emoji: _liabilityEmoji(_summary!.liabilities[i].liabilityType),
                                    name: _summary!.liabilities[i].name.isNotEmpty
                                        ? _summary!.liabilities[i].name
                                        : _liabilityLabel(_summary!.liabilities[i].liabilityType),
                                    type: _liabilityLabel(_summary!.liabilities[i].liabilityType) +
                                        (_summary!.liabilities[i].monthlyEmi != null
                                            ? ' · EMI ${currency.format(_summary!.liabilities[i].monthlyEmi)}'
                                            : ''),
                                    value: currency.format(_summary!.liabilities[i].outstanding),
                                    isAsset: false,
                                  ),
                                ),
                                childCount: _summary!.liabilities.length,
                              ),
                            ),
                          ),

                        // Add button at bottom
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
                            child: GestureDetector(
                              onTap: _showAddSheet,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_rounded,
                                        color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Add Asset or Liability',
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  String _assetEmoji(String type) {
    switch (type) {
      case 'real_estate': return '🏠';
      case 'vehicle': return '🚗';
      case 'cash': return '💰';
      case 'investments': return '📈';
      case 'fd_rd': return '🏦';
      case 'gold': return '💎';
      default: return '💼';
    }
  }

  String _assetLabel(String type) {
    switch (type) {
      case 'real_estate': return 'Property';
      case 'vehicle': return 'Vehicle';
      case 'cash': return 'Cash';
      case 'investments': return 'Investments';
      case 'fd_rd': return 'FD / RD';
      case 'gold': return 'Gold';
      default: return 'Other';
    }
  }

  String _liabilityEmoji(String type) {
    switch (type) {
      case 'home_loan': return '🏦';
      case 'car_loan': return '🚗';
      case 'credit_card': return '💳';
      case 'education_loan': return '📚';
      case 'personal_loan': return '💸';
      default: return '📋';
    }
  }

  String _liabilityLabel(String type) {
    switch (type) {
      case 'home_loan': return 'Home Loan';
      case 'car_loan': return 'Car Loan';
      case 'credit_card': return 'Credit Card';
      case 'education_loan': return 'Education Loan';
      case 'personal_loan': return 'Personal Loan';
      default: return 'Other';
    }
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary, required this.currency});
  final NetWorthSummary summary;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.netWorth >= 0;
    final netColor = isPositive ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF16213E),
            Color(0xFF0F0F0F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: netColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NET WORTH',
            style: GoogleFonts.dmSans(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currency.format(summary.netWorth),
                style: GoogleFonts.manrope(
                  color: netColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: netColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isPositive ? '↑ Positive' : '↓ Negative',
                  style: GoogleFonts.dmSans(
                    color: netColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Assets',
                      style: GoogleFonts.dmSans(
                          color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency.format(summary.totalAssets),
                      style: GoogleFonts.manrope(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white12,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Liabilities',
                        style: GoogleFonts.dmSans(
                            color: Colors.white38, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currency.format(summary.totalLiabilities),
                        style: GoogleFonts.manrope(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Asset / Liability Row ────────────────────────────────────────────────────

class _AssetRow extends StatefulWidget {
  const _AssetRow({
    required this.emoji,
    required this.name,
    required this.type,
    required this.value,
    required this.isAsset,
  });
  final String emoji, name, type, value;
  final bool isAsset;

  @override
  State<_AssetRow> createState() => _AssetRowState();
}

class _AssetRowState extends State<_AssetRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.isAsset ? AppColors.success : AppColors.danger;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered
                ? accentColor.withValues(alpha: 0.3)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              alignment: Alignment.center,
              child: Text(widget.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.type,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.value,
              style: GoogleFonts.manrope(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Swipe to Delete ──────────────────────────────────────────────────────────

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
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 26),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Delete?',
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            content: Text('This will permanently remove this entry.',
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Delete',
                    style: GoogleFonts.dmSans(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}

// ─── Empty Hint ───────────────────────────────────────────────────────────────

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message, required this.color});
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        message,
        style: GoogleFonts.dmSans(
          color: color.withValues(alpha: 0.7),
          fontSize: 13,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.wifi_off_rounded,
                  size: 28, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(error,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              child: Text('Retry',
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            ),
          ],
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

  static const _assetTypes = [
    ('real_estate', '🏠 Property'),
    ('vehicle', '🚗 Vehicle'),
    ('cash', '💰 Cash'),
    ('investments', '📈 Investments'),
    ('fd_rd', '🏦 FD/RD'),
    ('gold', '💎 Gold'),
  ];

  static const _liabilityTypes = [
    ('home_loan', '🏦 Home Loan'),
    ('car_loan', '🚗 Car Loan'),
    ('credit_card', '💳 Credit Card'),
    ('education_loan', '📚 Education Loan'),
    ('personal_loan', '💸 Personal Loan'),
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
    final value = double.tryParse(_valueCtrl.text.trim());
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_isAsset) {
      widget.onAssetAdded(_selectedType!, _nameCtrl.text.trim(), value);
    } else {
      widget.onLiabilityAdded(
        _selectedType!,
        _nameCtrl.text.trim(),
        value,
        double.tryParse(_emiCtrl.text.trim()),
        double.tryParse(_rateCtrl.text.trim()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _isAsset ? _assetTypes : _liabilityTypes;
    final accentColor = _isAsset ? AppColors.success : AppColors.danger;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Net Worth Item',
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _isAsset = true; _selectedType = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _isAsset
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isAsset
                              ? AppColors.success.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📈 Asset',
                        style: GoogleFonts.dmSans(
                          color: _isAsset ? AppColors.success : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _isAsset = false; _selectedType = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_isAsset
                            ? AppColors.danger.withValues(alpha: 0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isAsset
                              ? AppColors.danger.withValues(alpha: 0.4)
                              : AppColors.border,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '📉 Liability',
                        style: GoogleFonts.dmSans(
                          color: !_isAsset ? AppColors.danger : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: types.map((t) {
                final selected = _selectedType == t.$1;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = t.$1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? accentColor.withValues(alpha: 0.15) : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? accentColor.withValues(alpha: 0.5) : AppColors.border,
                      ),
                    ),
                    child: Text(
                      t.$2,
                      style: GoogleFonts.dmSans(
                        color: selected ? accentColor : AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            _DarkField(
              controller: _nameCtrl,
              hint: _isAsset ? 'Name (e.g. Flat in Pune)' : 'Name (e.g. SBI Home Loan)',
            ),
            const SizedBox(height: 10),
            _DarkField(
              controller: _valueCtrl,
              hint: _isAsset ? 'Current Value (₹)' : 'Outstanding Amount (₹)',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (!_isAsset) ...[
              const SizedBox(height: 10),
              _DarkField(
                controller: _emiCtrl,
                hint: 'Monthly EMI (₹) — optional',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _DarkField(
                controller: _rateCtrl,
                hint: 'Interest Rate (%) — optional',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                child: Text(
                  _isAsset ? 'Add Asset' : 'Add Liability',
                  style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
