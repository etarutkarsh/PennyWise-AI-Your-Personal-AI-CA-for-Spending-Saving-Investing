import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/goal_entity.dart';
import 'goal_plan_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<GoalEntity> _goals = [];
  bool _loading = true;
  String? _error;

  final _goalTypes = [
    ('🏠', 'House', AppColors.questBlue, const Color(0xFF1565C0)),
    ('🚗', 'Car', AppColors.questGreen, const Color(0xFF0F9D58)),
    ('✈️', 'Vacation', AppColors.questYellow, const Color(0xFFE65100)),
    ('💻', 'Laptop', AppColors.questPurple, const Color(0xFF6A1B9A)),
    ('💒', 'Wedding', AppColors.questRose, const Color(0xFFC62828)),
    ('🛡️', 'Emergency Fund', AppColors.questPeach, const Color(0xFFBF5820)),
    ('🎯', 'Retirement', AppColors.questGreen, const Color(0xFF1B5E20)),
    ('📚', 'Education', AppColors.questBlue, const Color(0xFF0D47A1)),
    ('✨', 'Custom', AppColors.surfaceElevated, AppColors.textSecondary),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final goals = await AppServices.instance.goals.getAll();
      if (mounted) setState(() { _goals = goals; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _showAddGoal() {
    final nameCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    final savedCtrl = TextEditingController();
    final deadlineCtrl = TextEditingController();
    String selectedType = 'Custom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text('New Quest',
                  style: GoogleFonts.dmSans(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _goalTypes.map((t) {
                    final selected = selectedType == t.$2;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedType = t.$2),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.orange : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: selected ? AppColors.orange : AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Text(t.$1),
                            const SizedBox(width: 6),
                            Text(t.$2,
                                style: GoogleFonts.dmSans(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              _DarkField(controller: nameCtrl, hint: 'Quest name'),
              const SizedBox(height: 10),
              _DarkField(
                  controller: targetCtrl,
                  hint: 'Target amount (₹)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _DarkField(
                  controller: savedCtrl,
                  hint: 'Already saved (₹)',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _DarkField(controller: deadlineCtrl, hint: 'Deadline (YYYY-MM-DD)'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Please enter a goal name')),
                      );
                      return;
                    }
                    final target = double.tryParse(targetCtrl.text.trim());
                    if (target == null || target <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Enter a valid target amount')),
                      );
                      return;
                    }
                    try {
                      await AppServices.instance.goals.create(
                        name: nameCtrl.text.trim(),
                        goalType: selectedType,
                        targetAmount: target,
                        currentSaved: double.tryParse(savedCtrl.text.trim()) ?? 0,
                        deadline: DateTime.tryParse(deadlineCtrl.text.trim()) ??
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(friendlyError(e))),
                        );
                      }
                    }
                  },
                  child: Text('Start Quest',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      nameCtrl.dispose();
      targetCtrl.dispose();
      savedCtrl.dispose();
      deadlineCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          backgroundColor: AppColors.surface,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Quests',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800)),
                          Text('${_goals.length} active goals',
                              style: GoogleFonts.dmSans(
                                  color: AppColors.textSecondary,
                                  fontSize: 14)),
                        ],
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _showAddGoal,
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
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                      child: CircularProgressIndicator(color: AppColors.orange)),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Could not load quests',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_goals.isEmpty)
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
                          child: const Icon(Icons.flag_outlined,
                              color: AppColors.textSecondary, size: 32),
                        ),
                        const SizedBox(height: 16),
                        Text('No quests yet',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text('Set a financial goal to get started',
                            style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddGoal,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Start a Quest'),
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
                      (_, i) => _GoalQuestCard(
                          goal: _goals[i], onUpdate: _load),
                      childCount: _goals.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalQuestCard extends StatefulWidget {
  const _GoalQuestCard({required this.goal, required this.onUpdate});
  final GoalEntity goal;
  final VoidCallback onUpdate;

  @override
  State<_GoalQuestCard> createState() => _GoalQuestCardState();
}

class _GoalQuestCardState extends State<_GoalQuestCard> {
  bool _hovered = false;

  static final _currency =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  Color get _bgColor {
    switch (widget.goal.goalType.toLowerCase()) {
      case 'house': return AppColors.questBlue;
      case 'car': return AppColors.questGreen;
      case 'vacation': return AppColors.questYellow;
      case 'laptop': return AppColors.questPurple;
      case 'wedding': return AppColors.questRose;
      default: return AppColors.questPeach;
    }
  }

  Color get _letterColor {
    switch (widget.goal.goalType.toLowerCase()) {
      case 'house': return const Color(0xFF1565C0);
      case 'car': return const Color(0xFF0F9D58);
      case 'vacation': return const Color(0xFFE65100);
      case 'laptop': return const Color(0xFF6A1B9A);
      case 'wedding': return const Color(0xFFC62828);
      default: return const Color(0xFFBF5820);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = widget.goal.targetAmount > 0
        ? (widget.goal.currentSaved / widget.goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final isComplete = pct >= 1.0;
    final barColor = isComplete ? AppColors.success : AppColors.orange;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GoalPlanScreen(goal: widget.goal),
        ),
      ),
      child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceElevated : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered
                ? _letterColor.withValues(alpha: 0.35)
                : AppColors.border,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: _letterColor.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(15)),
                  child: Center(
                    child: Text(
                      widget.goal.name.isNotEmpty
                          ? widget.goal.name[0].toUpperCase()
                          : '?',
                      style: GoogleFonts.dmSans(
                          color: _letterColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.goal.name,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '${_currency.format(widget.goal.currentSaved)} of ${_currency.format(widget.goal.targetAmount)}',
                        style: GoogleFonts.dmSans(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isComplete)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Complete!',
                        style: GoogleFonts.dmSans(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(pct * 100).toInt()}%',
                      style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: pct),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ),
            if (widget.goal.recommendedMonthlyContribution > 0) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.savings_outlined,
                      color: AppColors.textMuted, size: 12),
                  const SizedBox(width: 5),
                  Text(
                    'Save ${_currency.format(widget.goal.recommendedMonthlyContribution)}/month to hit target',
                    style: GoogleFonts.dmSans(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    ), // MouseRegion
    ); // GestureDetector
  }
}

class _DarkField extends StatelessWidget {
  const _DarkField(
      {required this.controller,
      required this.hint,
      this.keyboardType = TextInputType.text});
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.dmSans(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
