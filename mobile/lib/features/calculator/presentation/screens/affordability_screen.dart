import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart' show AppServices, friendlyError;
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/affordability_result.dart';

class AffordabilityScreen extends StatefulWidget {
  const AffordabilityScreen({super.key, this.salary = 0.0});
  final double salary;

  @override
  State<AffordabilityScreen> createState() => _AffordabilityScreenState();
}

class _AffordabilityScreenState extends State<AffordabilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _downPayCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _existingEmiCtrl = TextEditingController();

  bool _isLoading = false;
  bool _loanExpanded = false;
  int? _selectedTenure; // months
  AffordabilityResult? _result;
  String? _error;

  static const _tenureOptions = [12, 24, 36, 48, 60, 84, 120, 180, 240];

  @override
  void dispose() {
    _itemCtrl.dispose();
    _priceCtrl.dispose();
    _downPayCtrl.dispose();
    _rateCtrl.dispose();
    _existingEmiCtrl.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _result = null;
      _error = null;
    });
    try {
      final result = await AppServices.instance.affordability.check(
        itemName: _itemCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        downPayment: _loanExpanded ? double.tryParse(_downPayCtrl.text.trim()) : null,
        interestRatePercent: _loanExpanded ? double.tryParse(_rateCtrl.text.trim()) : null,
        tenureMonths: _loanExpanded ? _selectedTenure : null,
        existingMonthlyEmi: _loanExpanded ? double.tryParse(_existingEmiCtrl.text.trim()) : null,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
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
                          'Affordability Check',
                          style: GoogleFonts.dmSans(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          "What's the smartest way to buy this?",
                          style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Salary strip ───────────────────────────────────────────────
            if (widget.salary > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SalaryStrip(salary: widget.salary),
                ),
              ),
            if (widget.salary > 0)
              const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Form ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FormCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _SectionLabel(
                              icon: Icons.shopping_bag_outlined,
                              label: 'What do you want to buy?',
                            ),
                            const SizedBox(height: 14),
                            _DarkField(
                              controller: _itemCtrl,
                              hint: 'e.g. iPhone 16, New laptop, Car',
                              icon: Icons.inventory_2_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 10),
                            _DarkField(
                              controller: _priceCtrl,
                              hint: 'Price (₹)',
                              icon: Icons.currency_rupee_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) => (v == null || double.tryParse(v.trim()) == null)
                                  ? 'Enter a valid price'
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Loan section (collapsible) ─────────────────────
                      _FormCard(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _loanExpanded = !_loanExpanded),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.questBlue.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_balance_outlined,
                                        color: AppColors.questBlue, size: 16),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Buying on EMI / Loan',
                                      style: GoogleFonts.dmSans(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _loanExpanded ? 'Hide' : 'Optional',
                                    style: GoogleFonts.dmSans(
                                        color: AppColors.textMuted, fontSize: 12),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _loanExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                            if (_loanExpanded) ...[
                              const SizedBox(height: 16),
                              const Divider(height: 1, color: AppColors.border),
                              const SizedBox(height: 16),
                              _DarkField(
                                controller: _downPayCtrl,
                                hint: 'Down payment (₹)',
                                icon: Icons.payments_outlined,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                              const SizedBox(height: 10),
                              _DarkField(
                                controller: _rateCtrl,
                                hint: 'Interest rate (% per year)',
                                icon: Icons.percent_rounded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Loan Tenure',
                                style: GoogleFonts.dmSans(
                                    color: AppColors.textSecondary, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _tenureOptions.map((mo) {
                                  final label = mo >= 12 ? '${mo ~/ 12}yr' : '${mo}mo';
                                  final selected = _selectedTenure == mo;
                                  return GestureDetector(
                                    onTap: () => setState(() => _selectedTenure = selected ? null : mo),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.questBlue.withValues(alpha: 0.15)
                                            : AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: selected ? AppColors.questBlue : AppColors.border,
                                          width: selected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Text(
                                        label,
                                        style: GoogleFonts.dmSans(
                                          color: selected ? AppColors.questBlue : AppColors.textSecondary,
                                          fontSize: 12,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 10),
                              _DarkField(
                                controller: _existingEmiCtrl,
                                hint: 'Existing monthly EMIs (₹)',
                                icon: Icons.repeat_rounded,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── CTA ────────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: GestureDetector(
                          onTap: _isLoading ? null : _check,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isLoading ? AppColors.border : AppColors.orange,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_isLoading) ...[
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Analysing…',
                                    style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ] else ...[
                                  const Icon(Icons.psychology_outlined,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Analyse Purchase',
                                    style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Error ──────────────────────────────────────────────────────
            if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ErrorBanner(message: _error!, onRetry: _check),
                ),
              ),

            // ── Result ─────────────────────────────────────────────────────
            if (_result != null) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: _VerdictHeader(result: _result!),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _MetricsRow(result: _result!),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              if (_result!.goalImpacts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _GoalImpactSection(impacts: _result!.goalImpacts),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ReasonCard(result: _result!),
                ),
              ),
              if (_result!.scenarios.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Text(
                      'Scenario Comparison',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 200,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _result!.scenarios.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) =>
                          _ScenarioCard(scenario: _result!.scenarios[i]),
                    ),
                  ),
                ),
              ],
              if (_result!.warnings.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _WarningsList(warnings: _result!.warnings),
                  ),
                ),
              ],
              if (_result!.recommendations.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _RecommendationsList(recs: _result!.recommendations),
                  ),
                ),
              ],
              if (_result!.maxAffordablePrice != null) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _MaxAffordableCard(price: _result!.maxAffordablePrice!),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Salary strip ─────────────────────────────────────────────────────────────

class _SalaryStrip extends StatelessWidget {
  const _SalaryStrip({required this.salary});
  final double salary;

  static final _c = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orange.withValues(alpha: 0.12),
            AppColors.amber.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orange.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.orange, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Income',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
              Text(_c.format(salary),
                  style: GoogleFonts.manrope(
                      color: AppColors.orange, fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Max EMI (40%)',
                  style: GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 11)),
              Text(_c.format(salary * 0.40),
                  style: GoogleFonts.manrope(
                      color: AppColors.success, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Form card ────────────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.orange, size: 15),
        ),
        const SizedBox(width: 9),
        Text(
          label,
          style: GoogleFonts.dmSans(
              color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─── Dark field ───────────────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  const _DarkField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 18),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.error_outline, color: AppColors.danger, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message,
                    style: GoogleFonts.dmSans(color: AppColors.danger, fontSize: 13, height: 1.4)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Strength badge ───────────────────────────────────────────────────────────

class _StrengthBadge extends StatelessWidget {
  const _StrengthBadge({required this.strength, this.large = false});
  final RecommendationStrength strength;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (strength) {
      RecommendationStrength.high =>
        ('HIGH', AppColors.success, Icons.verified_rounded),
      RecommendationStrength.medium =>
        ('MEDIUM', AppColors.warning, Icons.info_rounded),
      RecommendationStrength.low =>
        ('LOW', AppColors.danger, Icons.warning_rounded),
    };

    if (large) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 9),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Verdict header ───────────────────────────────────────────────────────────

class _VerdictHeader extends StatefulWidget {
  const _VerdictHeader({required this.result});
  final AffordabilityResult result;

  @override
  State<_VerdictHeader> createState() => _VerdictHeaderState();
}

class _VerdictHeaderState extends State<_VerdictHeader> {
  bool _evidenceExpanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final (label, color, emoji) = switch (r.verdict) {
      'SAFE_TO_BUY' => ('Safe to Buy', AppColors.success, '✅'),
      'DONT_BUY' => ("Don't Buy Now", AppColors.danger, '🚫'),
      _ => ('Wait & Save', AppColors.warning, '⏳'),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StrengthBadge(strength: r.recommendationStrength, large: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: GoogleFonts.manrope(
                              color: color,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.reason,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (r.strengthEvidence.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _evidenceExpanded = !_evidenceExpanded),
              child: Row(
                children: [
                  Icon(Icons.verified_outlined, color: color, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'Recommendation Evidence',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _evidenceExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ),
            if (_evidenceExpanded) ...[
              const SizedBox(height: 8),
              ...r.strengthEvidence.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: color, size: 13),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            e,
                            style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Metrics row ──────────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.result});
  final AffordabilityResult result;

  static final _c = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final dti = result.dtiRatio;
    final dtiColor = dti == null
        ? AppColors.textSecondary
        : dti > 50
            ? AppColors.danger
            : dti > 40
                ? AppColors.warning
                : AppColors.success;

    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            icon: Icons.calendar_month_outlined,
            label: 'Monthly EMI',
            value: result.monthlyEmi != null ? _c.format(result.monthlyEmi) : '—',
            color: AppColors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.pie_chart_outline_rounded,
            label: 'Debt / Income',
            value: dti != null ? '${dti.toStringAsFixed(1)}%' : '—',
            color: dtiColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricTile(
            icon: Icons.savings_outlined,
            label: 'Free surplus',
            value: result.remainingMonthlySurplus != null
                ? _c.format(result.remainingMonthlySurplus)
                : '—',
            color: AppColors.success,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

// ─── Reason card ──────────────────────────────────────────────────────────────

class _ReasonCard extends StatefulWidget {
  const _ReasonCard({required this.result});
  final AffordabilityResult result;

  @override
  State<_ReasonCard> createState() => _ReasonCardState();
}

class _ReasonCardState extends State<_ReasonCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final (_, color, _) = switch (r.verdict) {
      'SAFE_TO_BUY' => ('', AppColors.success, ''),
      'DONT_BUY' => ('', AppColors.danger, ''),
      _ => ('', AppColors.warning, ''),
    };
    final allReasons = r.reasons;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: allReasons.length > 1
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: color, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Why this verdict?',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (allReasons.length > 1)
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...(_expanded ? allReasons : allReasons.take(1)).map(
            (reason) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reason,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scenario card ────────────────────────────────────────────────────────────

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.scenario});
  final AffordabilityScenario scenario;

  static final _c = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ScenarioDetailSheet(scenario: scenario),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verdictColor = switch (scenario.verdict) {
      'SAFE_TO_BUY' => AppColors.success,
      'DONT_BUY' => AppColors.danger,
      _ => AppColors.warning,
    };

    return GestureDetector(
      onTap: () => _showDetails(context),
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scenario.isRecommended
                ? AppColors.orange.withValues(alpha: 0.5)
                : AppColors.border,
            width: scenario.isRecommended ? 1.5 : 1,
          ),
          boxShadow: scenario.isRecommended
              ? [
                  BoxShadow(
                    color: AppColors.orange.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    scenario.label,
                    style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (scenario.isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Best',
                      style: GoogleFonts.dmSans(
                          color: AppColors.orange,
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _StrengthBadge(strength: scenario.recommendationStrength),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: scenario.confidence / 100.0,
                minHeight: 4,
                backgroundColor: verdictColor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(verdictColor),
              ),
            ),
            const SizedBox(height: 8),
            if (scenario.monthlyEmi != null)
              _ScenarioStat(
                label: 'EMI/mo',
                value: _c.format(scenario.monthlyEmi),
              ),
            if (scenario.totalCost != null)
              _ScenarioStat(
                label: 'Total cost',
                value: _c.format(scenario.totalCost),
              ),
            const Spacer(),
            Text(
              scenario.summary,
              style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary, fontSize: 10, height: 1.3),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.textMuted, size: 11),
                const SizedBox(width: 3),
                Text(
                  'Details',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScenarioStat extends StatelessWidget {
  const _ScenarioStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 10)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Scenario detail bottom sheet ─────────────────────────────────────────────

class _ScenarioDetailSheet extends StatelessWidget {
  const _ScenarioDetailSheet({required this.scenario});
  final AffordabilityScenario scenario;

  static final _c = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scenario.label,
                          style: GoogleFonts.manrope(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _StrengthBadge(strength: scenario.recommendationStrength),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    scenario.summary,
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                  if (scenario.monthlyEmi != null ||
                      scenario.totalCost != null ||
                      scenario.totalInterest != null) ...[
                    const SizedBox(height: 14),
                    _SheetDetailRow(
                        'Monthly EMI',
                        scenario.monthlyEmi != null
                            ? _c.format(scenario.monthlyEmi)
                            : null),
                    _SheetDetailRow(
                        'Total Interest',
                        scenario.totalInterest != null
                            ? _c.format(scenario.totalInterest)
                            : null),
                    _SheetDetailRow(
                        'Total Cost',
                        scenario.totalCost != null
                            ? _c.format(scenario.totalCost)
                            : null),
                  ],
                  if (scenario.whyThis.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _SheetSection(
                      title: 'Why this option?',
                      color: AppColors.success,
                      icon: Icons.thumb_up_outlined,
                      items: scenario.whyThis,
                      bullet: Icons.check_circle_outline_rounded,
                    ),
                  ],
                  if (scenario.whyNot.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SheetSection(
                      title: 'Why not this option?',
                      color: AppColors.danger,
                      icon: Icons.thumb_down_outlined,
                      items: scenario.whyNot,
                      bullet: Icons.cancel_outlined,
                    ),
                  ],
                  if (scenario.tradeoffs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      'Trade-offs',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...scenario.tradeoffs.map((t) {
                      final isPro = t.type == TradeoffType.pro;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isPro
                                  ? Icons.add_circle_outline_rounded
                                  : Icons.remove_circle_outline_rounded,
                              color: isPro ? AppColors.success : AppColors.danger,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                t.description,
                                style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetDetailRow extends StatelessWidget {
  const _SheetDetailRow(this.label, this.value);
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(label,
              style:
                  GoogleFonts.dmSans(color: AppColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(value!,
              style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SheetSection extends StatelessWidget {
  const _SheetSection({
    required this.title,
    required this.color,
    required this.icon,
    required this.items,
    required this.bullet,
  });
  final String title;
  final Color color;
  final IconData icon;
  final List<String> items;
  final IconData bullet;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.dmSans(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(bullet, color: color, size: 13),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.dmSans(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

// ─── Goal impact section ──────────────────────────────────────────────────────

class _GoalImpactSection extends StatelessWidget {
  const _GoalImpactSection({required this.impacts});
  final List<GoalImpact> impacts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.questBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flag_outlined,
                    color: AppColors.questBlue, size: 14),
              ),
              const SizedBox(width: 9),
              Text(
                'Goal Impact',
                style: GoogleFonts.dmSans(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'if you follow this recommendation',
                style: GoogleFonts.dmSans(
                    color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...impacts.map((impact) => _GoalImpactRow(impact: impact)),
        ],
      ),
    );
  }
}

class _GoalImpactRow extends StatelessWidget {
  const _GoalImpactRow({required this.impact});
  final GoalImpact impact;

  static IconData _goalIcon(String type) => switch (type) {
        'home' || 'house' => Icons.home_outlined,
        'car' => Icons.directions_car_outlined,
        'vacation' => Icons.flight_outlined,
        'laptop' || 'gadget' => Icons.laptop_outlined,
        'wedding' || 'marriage' => Icons.favorite_outline_rounded,
        'emergency_fund' => Icons.shield_outlined,
        'retirement' => Icons.self_improvement_outlined,
        'education' => Icons.school_outlined,
        _ => Icons.track_changes_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusLabel) = switch (impact.statusChange) {
      'ACCELERATED' => (AppColors.success, 'Accelerated'),
      'DELAYED' => (AppColors.warning, 'Delayed ${impact.monthsDelayed}mo'),
      'AT_RISK' => (AppColors.danger,
          impact.monthsDelayed >= 999
              ? 'At risk'
              : 'Delayed ${impact.monthsDelayed}mo'),
      _ => (AppColors.textMuted, 'Unaffected'),
    };

    final currentPct = impact.currentProgressPct / 100.0;
    final projectedPct = impact.projectedProgressPct / 100.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_goalIcon(impact.goalType),
                  color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  impact.goalName,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          // Before bar
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('Now',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 10)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: currentPct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.questBlue),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${impact.currentProgressPct.toStringAsFixed(0)}%',
                style: GoogleFonts.manrope(
                  color: AppColors.questBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // After bar
          Row(
            children: [
              SizedBox(
                width: 36,
                child: Text('+12mo',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textMuted, fontSize: 10)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: projectedPct.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${impact.projectedProgressPct.toStringAsFixed(0)}%',
                style: GoogleFonts.manrope(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Warnings list ────────────────────────────────────────────────────────────

class _WarningsList extends StatelessWidget {
  const _WarningsList({required this.warnings});
  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.warning, size: 14),
              const SizedBox(width: 6),
              Text('Watch out',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle,
                          color: AppColors.warning, size: 4),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(w,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Recommendations ──────────────────────────────────────────────────────────

class _RecommendationsList extends StatelessWidget {
  const _RecommendationsList({required this.recs});
  final List<String> recs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.questBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.questBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.questBlue, size: 14),
              const SizedBox(width: 6),
              Text('What to do',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ...recs.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: AppColors.questBlue.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${e.key + 1}',
                          style: GoogleFonts.dmSans(
                              color: AppColors.questBlue,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e.value,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─── Max affordable card ──────────────────────────────────────────────────────

class _MaxAffordableCard extends StatelessWidget {
  const _MaxAffordableCard({required this.price});
  final double price;

  static final _c = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.price_check_rounded,
              color: AppColors.textSecondary, size: 16),
          const SizedBox(width: 10),
          Text(
            'Max affordable price',
            style: GoogleFonts.dmSans(
                color: AppColors.textSecondary, fontSize: 13),
          ),
          const Spacer(),
          Text(
            _c.format(price),
            style: GoogleFonts.manrope(
              color: AppColors.success,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

