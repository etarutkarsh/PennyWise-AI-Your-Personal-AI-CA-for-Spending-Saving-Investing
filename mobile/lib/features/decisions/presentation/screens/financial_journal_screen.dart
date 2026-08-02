import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/decision_memory_entity.dart';

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class FinancialJournalScreen extends StatefulWidget {
  const FinancialJournalScreen({super.key});

  @override
  State<FinancialJournalScreen> createState() => _FinancialJournalScreenState();
}

class _FinancialJournalScreenState extends State<FinancialJournalScreen> {
  List<DecisionMemoryEntry> _entries = [];
  DecisionInsights? _insights;
  bool _loading = true;
  String? _error;

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
      final repo = AppServices.instance.decisionMemory;
      final results = await Future.wait([repo.timeline(), repo.insights()]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<DecisionMemoryEntry>;
        _insights = results[1] as DecisionInsights;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _openReviewSheet(DecisionMemoryEntry entry) async {
    final updated = await showModalBottomSheet<DecisionMemoryEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(entry: entry),
    );
    if (updated != null && mounted) {
      setState(() {
        final idx = _entries.indexWhere((e) => e.id == updated.id);
        if (idx != -1) _entries[idx] = updated;
      });
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: AppColors.textPrimary,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Financial Journal',
          style: GoogleFonts.manrope(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: AppColors.textSecondary,
            tooltip: 'Settings',
            onPressed: () {}, // no-op for now
          ),
          const SizedBox(width: 4),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return _SkeletonList();
    if (_error != null) return _ErrorView(error: _error!, onRetry: _load);
    if (_entries.isEmpty) return const _EmptyState();

    // Group entries by year (descending)
    final grouped = <int, List<DecisionMemoryEntry>>{};
    for (final e in _entries) {
      grouped.putIfAbsent(e.createdYear, () => []).add(e);
    }
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Flatten into a mixed list: [int year, entry, entry, int year, ...]
    final items = <Object>[];
    for (final year in years) {
      items.add(year);
      items.addAll(grouped[year]!);
    }

    return CustomScrollView(
      slivers: [
        // Insights strip
        if (_insights != null)
          SliverToBoxAdapter(
            child: _InsightsStrip(insights: _insights!),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Timeline
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                if (item is int) {
                  return _YearDivider(year: item);
                }
                final entry = item as DecisionMemoryEntry;
                return _TimelineEntryCard(
                  entry: entry,
                  onReview: () => _openReviewSheet(entry),
                );
              },
              childCount: items.length,
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Insights Strip
// ---------------------------------------------------------------------------

class _InsightsStrip extends StatelessWidget {
  const _InsightsStrip({required this.insights});

  final DecisionInsights insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _StatChip(
            value: '${insights.totalDecisions}',
            label: 'decisions',
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: insights.followRateLabel,
            label: '',
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: insights.accuracyLabel,
            label: '',
          ),
          const SizedBox(width: 8),
          _StatChip(
            value: '${insights.pendingReviews}',
            label: 'pending',
            highlight: insights.pendingReviews > 0,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: highlight ? AppColors.accent : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: GoogleFonts.manrope(
                color: highlight ? AppColors.accent : AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Year Divider
// ---------------------------------------------------------------------------

class _YearDivider extends StatelessWidget {
  const _YearDivider({required this.year});

  final int year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(
            child: Divider(color: AppColors.border, thickness: 1),
          ),
          const SizedBox(width: 12),
          Text(
            '$year',
            style: GoogleFonts.dmSans(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(color: AppColors.border, thickness: 1),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline Entry Card
// ---------------------------------------------------------------------------

class _TimelineEntryCard extends StatelessWidget {
  const _TimelineEntryCard({
    required this.entry,
    required this.onReview,
  });

  final DecisionMemoryEntry entry;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT — timeline bar + dot
          _TimelineSide(color: entry.verdictColor, isPending: entry.isPending),
          const SizedBox(width: 12),
          // RIGHT — card
          Expanded(child: _EntryCard(entry: entry, onReview: onReview)),
        ],
      ),
    );
  }
}

// ── Timeline side column ────────────────────────────────────────────────────

class _TimelineSide extends StatefulWidget {
  const _TimelineSide({required this.color, required this.isPending});

  final Color color;
  final bool isPending;

  @override
  State<_TimelineSide> createState() => _TimelineSideState();
}

class _TimelineSideState extends State<_TimelineSide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (widget.isPending) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.isPending ? AppColors.textMuted : widget.color;

    return SizedBox(
      width: 24,
      child: Column(
        children: [
          // Top line segment
          Container(width: 2, height: 12, color: AppColors.border),
          // Dot
          widget.isPending
              ? AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, __) => Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: dotColor.withValues(alpha: _pulse.value),
                      shape: BoxShape.circle,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                  ),
                )
              : Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
          // Bottom line (extends down)
          Container(
            width: 2,
            height: 80,
            color: AppColors.border,
          ),
        ],
      ),
    );
  }
}

// ── Entry card ───────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.onReview});

  final DecisionMemoryEntry entry;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: item name + verdict badge
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.itemName,
                  style: GoogleFonts.manrope(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              _VerdictBadge(entry: entry),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: price + strength + date
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                entry.formattedPrice,
                style: GoogleFonts.manrope(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              _StrengthBadge(strength: entry.recommendationStrength),
              Text(
                entry.formattedDate,
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Status-specific content
          if (entry.isPending) ...[
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 13, color: Color(0xFFFFB830)),
                const SizedBox(width: 4),
                Text(
                  'Review due: ${entry.reviewAfterFormatted}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFFFFB830),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: onReview,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Mark Outcome'),
                ),
              ],
            ),
          ] else ...[
            // Followed / didn't follow
            Row(
              children: [
                if (entry.effectiveFollowed != null) ...[
                  Icon(
                    entry.effectiveFollowed!
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 14,
                    color: entry.effectiveFollowed!
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.effectiveFollowed! ? 'Followed' : "Didn't Follow",
                    style: GoogleFonts.dmSans(
                      color: entry.effectiveFollowed!
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (entry.effectiveAccuracy != null) ...[
                  const SizedBox(width: 12),
                  Text(
                    'Accuracy: ${(entry.effectiveAccuracy! * 100).round()}%',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            // First lesson if available
            if (entry.outcome?.lessons != null &&
                entry.outcome!.lessons!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.outcome!.lessons!.first,
                style: GoogleFonts.dmSans(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Verdict Badge ─────────────────────────────────────────────────────────────

class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.entry});

  final DecisionMemoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final color = entry.verdictColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        entry.verdictLabel,
        style: GoogleFonts.dmSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Strength Badge ────────────────────────────────────────────────────────────

class _StrengthBadge extends StatelessWidget {
  const _StrengthBadge({required this.strength});

  final String strength;

  Color get _color {
    switch (strength) {
      case 'HIGH':
        return AppColors.success;
      case 'MEDIUM':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        strength,
        style: GoogleFonts.dmSans(
          color: _color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Review Bottom Sheet
// ---------------------------------------------------------------------------

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet({required this.entry});

  final DecisionMemoryEntry entry;

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  bool? _followed;
  final _scoreCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  @override
  void dispose() {
    _scoreCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final scoreText = _scoreCtrl.text.trim();
    final score = int.tryParse(scoreText);
    if (_followed == null) return;
    if (score == null || score < 0 || score > 100) {
      setState(() => _submitError = 'Enter a score between 0 and 100');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final updated = await AppServices.instance.decisionMemory.submitReview(
        widget.entry.id,
        _followed!,
        score,
      );
      if (mounted) Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = friendlyError(e);
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
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
          const SizedBox(height: 20),

          Text(
            'Did you follow this recommendation?',
            style: GoogleFonts.manrope(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${widget.entry.verdictLabel}: ${widget.entry.itemName}',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Yes / No cards
          Row(
            children: [
              _ChoiceCard(
                label: 'Yes, I followed it',
                icon: Icons.check_circle_outline_rounded,
                selected: _followed == true,
                color: AppColors.success,
                onTap: () => setState(() => _followed = true),
              ),
              const SizedBox(width: 12),
              _ChoiceCard(
                label: "No, I didn't",
                icon: Icons.cancel_outlined,
                selected: _followed == false,
                color: AppColors.textSecondary,
                onTap: () => setState(() => _followed = false),
              ),
            ],
          ),

          if (_followed != null) ...[
            const SizedBox(height: 20),
            Text(
              'Your financial health score today (0–100):',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _scoreCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 78',
                hintStyle: GoogleFonts.dmSans(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ],

          if (_submitError != null) ...[
            const SizedBox(height: 10),
            Text(
              _submitError!,
              style: GoogleFonts.dmSans(
                color: AppColors.danger,
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_followed == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppColors.textMuted, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: selected ? color : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Your financial journal is empty',
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Every time you use the Affordability Check, your decision is recorded here.',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.push('/affordability'),
              icon: const Icon(Icons.calculate_outlined, size: 18),
              label: const Text('Try the Decision Engine →'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
// Error State
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              error,
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
// Skeleton / Loading State
// ---------------------------------------------------------------------------

class _SkeletonList extends StatefulWidget {
  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerColor =
            AppColors.border.withValues(alpha: _anim.value + 0.3);
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Insights strip skeleton
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 20),
            // 3 entry skeletons
            for (int i = 0; i < 3; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(width: 2, height: 12, color: shimmerColor),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 80, color: shimmerColor),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

// Ensure unused import is suppressed
// ignore: unused_element
double _unused() => math.pi;
