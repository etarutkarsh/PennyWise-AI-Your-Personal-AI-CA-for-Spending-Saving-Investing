import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/repositories/digital_twin_repository.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with SingleTickerProviderStateMixin {
  DigitalTwin? _twin;
  bool _loading = true;
  String? _error;
  bool _refreshing = false;

  late AnimationController _ringCtrl;
  late Animation<double> _ringAnim;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ringAnim = CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic);
    _load();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final twin = await AppServices.instance.twin.getTwin();
      if (!mounted) return;
      setState(() {
        _twin = twin;
        _loading = false;
      });
      _ringCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyError(e);
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final twin = await AppServices.instance.twin.refresh();
      if (!mounted) return;
      setState(() {
        _twin = twin;
        _refreshing = false;
      });
      _ringCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _refreshing = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? _buildSkeleton()
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  // ── Skeleton loading state ────────────────────────────────────────────────

  Widget _buildSkeleton() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeroSkeleton()),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _SkeletonCard(height: 120),
                const SizedBox(height: 16),
                _SkeletonCard(height: 220),
                const SizedBox(height: 16),
                _SkeletonCard(height: 80),
                const SizedBox(height: 16),
                _SkeletonCard(height: 180),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213E), Color(0xFF0D1B35)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
            const SizedBox(height: 24),
            _SkeletonBox(width: 200, height: 14),
            const SizedBox(height: 10),
            _SkeletonBox(width: 140, height: 12),
          ],
        ),
      ),
    );
  }

  // ── Error state ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: AppColors.danger,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Couldn't load your Digital Twin",
                      style: GoogleFonts.manrope(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _error ?? 'Something went wrong.',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent() {
    final twin = _twin!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHero(twin)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _NetWorthCard(twin: twin),
                const SizedBox(height: 20),
                _ProjectionChartCard(twin: twin),
                const SizedBox(height: 20),
                _BehaviorBanner(
                    behaviorFactor: twin.behaviorFactor ?? 0.75),
                if (twin.goalTrajectories.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _GoalTrajectoriesSection(
                      goals: twin.goalTrajectories.take(4).toList()),
                ],
                const SizedBox(height: 20),
                _DataCompletenessCard(
                  twin: twin,
                  onRefresh: _refresh,
                  refreshing: _refreshing,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── App bar (inline) ──────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Financial Digital Twin',
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero section ──────────────────────────────────────────────────────────

  Widget _buildHero(DigitalTwin twin) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16213E), Color(0xFF0D1B35)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back button + title row
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FINANCIAL DIGITAL TWIN',
                        style: GoogleFonts.dmSans(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'Your Complete Financial Picture',
                        style: GoogleFonts.manrope(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Twin Score Ring
              _TwinScoreRing(twin: twin, animation: _ringAnim),

              const SizedBox(height: 28),

              // Three stat pills
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeroPill(
                    label: 'Net Worth',
                    value: twin.netWorthFormatted,
                    valueColor: twin.isNetWorthPositive
                        ? AppColors.success
                        : AppColors.danger,
                  ),
                  const SizedBox(width: 10),
                  _HeroPill(
                    label: 'EF Coverage',
                    value: twin.efLabel,
                    valueColor: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  _HeroPill(
                    label: 'DTI Ratio',
                    value: twin.dtiLabel,
                    valueColor: Colors.white,
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

// ─── Twin Score Ring ──────────────────────────────────────────────────────────

class _TwinScoreRing extends StatelessWidget {
  const _TwinScoreRing({required this.twin, required this.animation});
  final DigitalTwin twin;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final progress = (twin.twinScore / 100.0) * animation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // Glow
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: twin.twinScoreColor.withValues(alpha: 0.25),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(140, 140),
                painter: _RingPainter(
                  progress: progress,
                  color: twin.twinScoreColor,
                  bgColor: Colors.white.withValues(alpha: 0.08),
                  strokeWidth: 9,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${twin.twinScore}',
                    style: GoogleFonts.manrope(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: twin.twinScoreColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      twin.twinScoreLabel,
                      style: GoogleFonts.dmSans(
                        color: twin.twinScoreColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Hero Pill ────────────────────────────────────────────────────────────────

class _HeroPill extends StatelessWidget {
  const _HeroPill(
      {required this.label, required this.value, required this.valueColor});
  final String label, value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Net Worth Card ───────────────────────────────────────────────────────────

class _NetWorthCard extends StatelessWidget {
  const _NetWorthCard({required this.twin});
  final DigitalTwin twin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net Worth',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            twin.netWorthFormatted,
            style: GoogleFonts.manrope(
              color: twin.isNetWorthPositive
                  ? AppColors.success
                  : AppColors.danger,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            twin.isNetWorthPositive
                ? 'Your assets exceed your liabilities'
                : 'Work on reducing liabilities to turn positive',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _NetWorthStat(
                  label: 'Total Assets',
                  value: twin.assetsFormatted,
                  color: AppColors.success,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetWorthStat(
                  label: 'Liabilities',
                  value: twin.liabilitiesFormatted,
                  color: AppColors.danger,
                  icon: Icons.trending_down_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _NetWorthStat(
                  label: 'Monthly Surplus',
                  value: twin.surplusFormatted,
                  color: AppColors.amber,
                  icon: Icons.savings_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetWorthStat extends StatelessWidget {
  const _NetWorthStat(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});
  final String label, value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.manrope(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Projection Chart Card ────────────────────────────────────────────────────

class _ProjectionChartCard extends StatelessWidget {
  const _ProjectionChartCard({required this.twin});
  final DigitalTwin twin;

  @override
  Widget build(BuildContext context) {
    final sparkline = twin.projectionSeries
        .where((p) => p.monthsFromNow <= 24)
        .toList()
      ..sort((a, b) => a.monthsFromNow.compareTo(b.monthsFromNow));

    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A7A40), Color(0xFF0F9D58)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Net Worth Projection',
                    style: GoogleFonts.manrope(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '24-month forecast based on your behavior',
                    style: GoogleFonts.dmSans(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          if (sparkline.length >= 2)
            SizedBox(
              height: 160,
              child: _ProjectionLineChart(points: sparkline),
            )
          else
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Add income, assets and goals to see your projection',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Milestone callouts
          Row(
            children: [
              _MilestoneCallout(
                  label: '1Y', value: twin.projection12mFormatted),
              const SizedBox(width: 8),
              _MilestoneCallout(
                  label: '3Y', value: twin.projection3yrFormatted),
              const SizedBox(width: 8),
              _MilestoneCallout(
                  label: '5Y', value: twin.projection5yrFormatted),
              const SizedBox(width: 8),
              _MilestoneCallout(
                  label: '10Y', value: twin.projection10yrFormatted),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectionLineChart extends StatelessWidget {
  const _ProjectionLineChart({required this.points});
  final List<ProjectionPoint> points;

  @override
  Widget build(BuildContext context) {
    final spots = points
        .map((p) =>
            FlSpot(p.monthsFromNow.toDouble(), p.netWorth / 100000))
        .toList();

    final minY = spots.map((s) => s.y).reduce(min);
    final maxY = spots.map((s) => s.y).reduce(max);
    final yPad = (maxY - minY).abs() * 0.15 + 0.5;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ((maxY - minY) / 4).clamp(0.5, double.infinity),
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (val, _) {
                final label = val >= 0
                    ? '₹${val.toStringAsFixed(0)}L'
                    : '-₹${val.abs().toStringAsFixed(0)}L';
                return Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 6,
              getTitlesWidget: (val, _) {
                final month = val.toInt();
                if (month == 0) return const SizedBox.shrink();
                return Text(
                  'M$month',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 1,
        maxX: 24,
        minY: minY - yPad,
        maxY: maxY + yPad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.success,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.success.withValues(alpha: 0.18),
                  AppColors.success.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneCallout extends StatelessWidget {
  const _MilestoneCallout({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.manrope(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Behavior Banner ──────────────────────────────────────────────────────────

class _BehaviorBanner extends StatelessWidget {
  const _BehaviorBanner({required this.behaviorFactor});
  final double behaviorFactor;

  @override
  Widget build(BuildContext context) {
    final pct = ((behaviorFactor - 0.5) / (1.15 - 0.5)).clamp(0.0, 1.0);
    final label = behaviorFactor >= 1.0
        ? 'Excellent'
        : behaviorFactor >= 0.85
            ? 'Good'
            : behaviorFactor >= 0.65
                ? 'Average'
                : 'Needs Work';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded,
                  color: AppColors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'Behavioral Adjustment',
                style: GoogleFonts.manrope(
                  color: AppColors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Discipline factor: ',
                style: GoogleFonts.dmSans(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                '${behaviorFactor.toStringAsFixed(2)}×',
                style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.dmSans(
                    color: AppColors.amber,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.surfaceElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.amber),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your projections are scaled by this factor based on your financial behavior patterns.',
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goal Trajectories Section ────────────────────────────────────────────────

class _GoalTrajectoriesSection extends StatelessWidget {
  const _GoalTrajectoriesSection({required this.goals});
  final List<GoalTrajectory> goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flag_rounded,
                color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 8),
            Text(
              'Goal Trajectories',
              style: GoogleFonts.manrope(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'How your goals are progressing at current saving rate',
          style: GoogleFonts.dmSans(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 14),
        ...goals.map((g) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalTrajectoryCard(goal: g),
            )),
      ],
    );
  }
}

class _GoalTrajectoryCard extends StatelessWidget {
  const _GoalTrajectoryCard({required this.goal});
  final GoalTrajectory goal;

  @override
  Widget build(BuildContext context) {
    final pct = goal.completionProbability.clamp(0.0, 1.0);
    final color = goal.statusColor;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Text(
                  goal.goalName,
                  style: GoogleFonts.manrope(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  goal.status.replaceAll('_', ' '),
                  style: GoogleFonts.dmSans(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (goal.deadlineFormatted != null) ...[
            const SizedBox(height: 4),
            Text(
              'Target: ${goal.deadlineFormatted}',
              style: GoogleFonts.dmSans(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Probability bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(pct * 100).toStringAsFixed(0)}% likely to complete',
                style: GoogleFonts.dmSans(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (goal.status != 'ACHIEVED' && goal.monthsToCompletion < 999)
                Text(
                  '${goal.monthsToCompletion}mo to complete',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Data Completeness Card ───────────────────────────────────────────────────

class _DataCompletenessCard extends StatelessWidget {
  const _DataCompletenessCard({
    required this.twin,
    required this.onRefresh,
    required this.refreshing,
  });
  final DigitalTwin twin;
  final VoidCallback onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final hasIncome =
        twin.monthlyIncome != null && twin.monthlyIncome! > 0;
    final hasAssets =
        twin.totalAssets != null && twin.totalAssets! > 0;
    final hasLiabilities =
        twin.totalLiabilities != null && twin.totalLiabilities! > 0;
    final hasGoals = twin.goalTrajectories.isNotEmpty;
    final hasBehavior = twin.behaviorFactor != null;
    final hasTransactions =
        twin.monthlyExpenses != null && twin.monthlyExpenses! > 0;

    return Container(
      padding: const EdgeInsets.all(24),
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
              const Icon(Icons.donut_large_rounded,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Twin Completeness',
                style: GoogleFonts.manrope(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: twin.twinScoreColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${twin.twinScore}/100',
                  style: GoogleFonts.manrope(
                    color: twin.twinScoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _CheckRow(label: 'Monthly Income', checked: hasIncome),
          _CheckRow(label: 'Assets Logged', checked: hasAssets),
          _CheckRow(label: 'Liabilities Tracked', checked: hasLiabilities),
          _CheckRow(label: 'Financial Goals Set', checked: hasGoals),
          _CheckRow(label: 'Behavioral Profile Built', checked: hasBehavior),
          _CheckRow(label: 'Transaction History', checked: hasTransactions),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: refreshing ? null : onRefresh,
              icon: refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(refreshing ? 'Refreshing...' : 'Refresh Twin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: GoogleFonts.dmSans(
                  fontSize: 14,
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

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.label, required this.checked});
  final String label;
  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: checked
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(
                color: checked
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.border,
              ),
            ),
            child: Icon(
              checked ? Icons.check_rounded : Icons.remove_rounded,
              color: checked ? AppColors.success : AppColors.textMuted,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: checked
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: checked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });
  final double progress;
  final Color color, bgColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint..color = bgColor);

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress.clamp(0.0, 1.0),
      false,
      paint..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Skeleton helpers ─────────────────────────────────────────────────────────

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height});
  final double width, height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
