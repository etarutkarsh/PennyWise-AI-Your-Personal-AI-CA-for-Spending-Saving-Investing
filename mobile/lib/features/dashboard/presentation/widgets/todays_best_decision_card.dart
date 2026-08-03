import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:pennywise_ai/application/decision/record_decision_lifecycle_use_case.dart';
import 'package:pennywise_ai/core/di/injection.dart';
import 'package:pennywise_ai/domain/decision/decision.dart';
import 'package:pennywise_ai/domain/value_objects/ids.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../decisions/data/models/today_decision_model.dart';

class TodaysBestDecisionCard extends StatefulWidget {
  const TodaysBestDecisionCard({super.key});

  @override
  State<TodaysBestDecisionCard> createState() => _TodaysBestDecisionCardState();
}

class _TodaysBestDecisionCardState extends State<TodaysBestDecisionCard> {
  TodayDecisionModel? _decision;
  DecisionId? _decisionId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await AppServices.instance.todayDecision.getToday();
      if (!mounted) return;
      setState(() {
        _decision = d;
        _decisionId = DecisionId(
          d.decisionId.isNotEmpty
              ? d.decisionId
              : 'local-${DateTime.now().millisecondsSinceEpoch}',
        );
        _loading = false;
      });
      _recordLifecycle(DecisionLifecycleState.viewed);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Fire-and-forget lifecycle recording — must never break the UI.
  void _recordLifecycle(DecisionLifecycleState state) {
    final id = _decisionId;
    if (id == null) return;
    // Do not await; failures are absorbed inside the use case.
    sl<RecordDecisionLifecycleUseCase>().call(
      RecordDecisionLifecycleParams(id, state),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _skeleton();
    if (_decision == null) return const SizedBox.shrink();
    return _card(_decision!);
  }

  Widget _skeleton() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
        ),
      );

  Widget _card(TodayDecisionModel d) {
    final priorityColor = _priorityColor(d.priority);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B2A), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(d, priorityColor),
          _reasonsSection(d),
          _impactSection(d),
          _ctaRow(d, priorityColor),
          _footer(d),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _header(TodayDecisionModel d, Color priorityColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'TODAY\'S BEST DECISION',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const Spacer(),
              _priorityBadge(d.priority, priorityColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.icon, style: const TextStyle(fontSize: 30)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.headline,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      d.subheadline,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                        height: 1.4,
                      ),
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

  Widget _priorityBadge(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            priority,
            style: GoogleFonts.dmSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Why today ──────────────────────────────────────────────────────────────

  Widget _reasonsSection(TodayDecisionModel d) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY TODAY',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          ...d.reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      r,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.78),
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

  // ── Impact ─────────────────────────────────────────────────────────────────

  Widget _impactSection(TodayDecisionModel d) {
    final imp = d.impact;
    final metrics = <_ImpactMetric>[
      _ImpactMetric(
        'Health Score',
        '${imp.healthScoreCurrent} → ${imp.healthScoreAfter}',
        '+${imp.healthScoreAfter - imp.healthScoreCurrent}',
      ),
      _ImpactMetric(
        'Goal Success',
        '${imp.goalSuccessRateCurrent}% → ${imp.goalSuccessRateAfter}%',
        '+${imp.goalSuccessRateAfter - imp.goalSuccessRateCurrent}%',
      ),
      if (imp.runwayMonthsAdded > 0)
        _ImpactMetric(
          'Safety Runway',
          '+${imp.runwayMonthsAdded} months',
          '',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMPACT IF YOU ACT NOW',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: metrics
                .map((m) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: m == metrics.last ? 0 : 10),
                        child: _impactTile(m),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _impactTile(_ImpactMetric m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            m.label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            m.value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (m.delta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              m.delta,
              style: GoogleFonts.dmSans(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── CTAs ───────────────────────────────────────────────────────────────────

  Widget _ctaRow(TodayDecisionModel d, Color priorityColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _outlineBtn(
              'Explain',
              onTap: () => _showExplainSheet(d),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _outlineBtn(
              'Compare',
              onTap: () => _showOptionsSheet(d),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                _recordLifecycle(DecisionLifecycleState.accepted);
                _showOptionsSheet(d);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View Options',
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineBtn(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.18), width: 1),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _footer(TodayDecisionModel d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Text(
            'Supported by  ',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.28),
              fontSize: 11,
            ),
          ),
          Text(
            d.recommendedAction.instrument,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.42),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  void _showExplainSheet(TodayDecisionModel d) {
    showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _ExplainSheet(decision: d),
    ).then((openOptions) {
      if (mounted && openOptions == true) _showOptionsSheet(d);
    });
  }

  void _showOptionsSheet(TodayDecisionModel d) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0D1B2A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _OptionsSheet(decision: d),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Color _priorityColor(String priority) {
    return switch (priority) {
      'HIGH' => AppColors.danger,
      'LOW' => AppColors.primary,
      _ => AppColors.accent,
    };
  }
}

// ── Explain sheet ─────────────────────────────────────────────────────────────

class _ExplainSheet extends StatelessWidget {
  const _ExplainSheet({required this.decision});
  final TodayDecisionModel decision;

  @override
  Widget build(BuildContext context) {
    final imp = decision.impact;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${decision.icon}  ${decision.headline}',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            decision.subheadline,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _sheetLabel('WHY THIS DECISION'),
          const SizedBox(height: 12),
          ...decision.reasons.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, color: AppColors.accent, size: 6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r,
                      style: GoogleFonts.dmSans(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _sheetLabel('PROJECTED IMPACT'),
          const SizedBox(height: 12),
          _impactRow('Health Score',
              '${imp.healthScoreCurrent} → ${imp.healthScoreAfter}',
              '+${imp.healthScoreAfter - imp.healthScoreCurrent} points'),
          const SizedBox(height: 10),
          _impactRow('Goal Success Rate',
              '${imp.goalSuccessRateCurrent}% → ${imp.goalSuccessRateAfter}%',
              '+${imp.goalSuccessRateAfter - imp.goalSuccessRateCurrent}%'),
          if (imp.runwayMonthsAdded > 0) ...[
            const SizedBox(height: 10),
            _impactRow('Safety Runway', '+${imp.runwayMonthsAdded} months',
                'additional financial cushion'),
          ],
          const SizedBox(height: 24),
          _sheetLabel('WHAT TO DO'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Instrument', decision.recommendedAction.instrument),
                const SizedBox(height: 8),
                _detailRow('Monthly Amount',
                    '₹${decision.recommendedAction.monthlyAmount.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _detailRow('Timeline', decision.recommendedAction.timeline),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context, true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'View Execution Options',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetLabel(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          color: Colors.white.withValues(alpha: 0.38),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      );

  Widget _impactRow(String label, String value, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value,
                  style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
              Text(sub,
                  style: GoogleFonts.dmSans(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value,
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

// ── Options sheet ─────────────────────────────────────────────────────────────

class _OptionsSheet extends StatelessWidget {
  const _OptionsSheet({required this.decision});
  final TodayDecisionModel decision;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Execution Options',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ways to execute: ${decision.headline}',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ranked by suitability, returns, and risk — not by commission.',
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          ...decision.partnerOptions.asMap().entries.map(
                (entry) => _optionTile(entry.key + 1, entry.value),
              ),
        ],
      ),
    );
  }

  Widget _optionTile(int rank, PartnerOptionModel option) {
    final ctaColor = option.ctaLabel == 'Open'
        ? AppColors.primary
        : option.ctaLabel == 'Compare'
            ? AppColors.accent
            : Colors.white.withValues(alpha: 0.4);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: GoogleFonts.dmSans(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
                  option.partner,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (option.rate > 0) ...[
                      Text(
                        '${option.rate.toStringAsFixed(2)}%',
                        style: GoogleFonts.dmSans(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        option.feature,
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (option.minAmount > 0)
                  Text(
                    'Min ₹${option.minAmount.toStringAsFixed(0)}/month',
                    style: GoogleFonts.dmSans(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: ctaColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: ctaColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              option.ctaLabel,
              style: GoogleFonts.dmSans(
                color: ctaColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _ImpactMetric {
  const _ImpactMetric(this.label, this.value, this.delta);
  final String label;
  final String value;
  final String delta;
}
