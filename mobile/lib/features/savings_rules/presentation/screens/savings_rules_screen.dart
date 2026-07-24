import 'package:flutter/material.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/savings_rule_model.dart';

class SavingsRulesScreen extends StatefulWidget {
  const SavingsRulesScreen({super.key});

  @override
  State<SavingsRulesScreen> createState() => _SavingsRulesScreenState();
}

class _SavingsRulesScreenState extends State<SavingsRulesScreen> {
  List<SavingsRuleModel> _rules = [];
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
      final rules = await AppServices.instance.savingsRules.getAll();
      if (mounted) setState(() => _rules = rules);
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleActive(SavingsRuleModel rule) async {
    try {
      final updated = await AppServices.instance.savingsRules.toggleActive(rule.id);
      if (mounted) {
        setState(() {
          final idx = _rules.indexWhere((r) => r.id == rule.id);
          if (idx != -1) _rules[idx] = updated;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _delete(SavingsRuleModel rule) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete rule?'),
        content: Text('Remove "${_ruleLabel(rule.triggerType)}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AppServices.instance.savingsRules.delete(rule.id);
      if (mounted) setState(() => _rules.removeWhere((r) => r.id == rule.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddRuleSheet(
        onSaved: (rule) {
          if (mounted) setState(() => _rules.insert(0, rule));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Rules'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_rules.isEmpty) {
      return _EmptyState(onAdd: _openAddSheet);
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _rules.length,
        itemBuilder: (context, i) => _RuleCard(
          rule: _rules[i],
          onToggle: () => _toggleActive(_rules[i]),
          onDelete: () => _delete(_rules[i]),
        ),
      ),
    );
  }
}

String _ruleEmoji(String triggerType) {
  return switch (triggerType) {
    'round_up' => '🪙',
    'surplus_sweep' => '💸',
    'fixed_monthly' => '📅',
    'category_limit_alert' => '🔔',
    _ => '💰',
  };
}

String _ruleLabel(String triggerType) {
  return switch (triggerType) {
    'round_up' => 'Round-Up Savings',
    'surplus_sweep' => 'Surplus Sweep',
    'fixed_monthly' => 'Fixed Monthly',
    'category_limit_alert' => 'Budget Alert',
    _ => triggerType,
  };
}

String _ruleDescription(SavingsRuleModel rule) {
  final config = rule.config;
  return switch (rule.triggerType) {
    'round_up' => () {
        final roundTo = config['round_to'] ?? 100;
        return 'Rounds every transaction up to nearest ₹$roundTo and saves the difference';
      }(),
    'surplus_sweep' => () {
        final percent = config['percent'] ?? 10;
        return 'Sweeps $percent% of leftover budget to savings each month';
      }(),
    'fixed_monthly' => () {
        final amount = config['amount'] ?? 0;
        return 'Saves ₹$amount automatically on the 1st of every month';
      }(),
    'category_limit_alert' => () {
        final threshold = config['threshold_percent'] ?? 80;
        final cat = rule.categoryName ?? 'Category';
        return 'Alerts when $cat reaches $threshold% of budget limit';
      }(),
    _ => '',
  };
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.onToggle,
    required this.onDelete,
  });

  final SavingsRuleModel rule;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(_ruleEmoji(rule.triggerType),
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ruleLabel(rule.triggerType),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _ruleDescription(rule),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              children: [
                Switch(
                  value: rule.active,
                  onChanged: (_) => onToggle(),
                  activeColor: AppColors.primary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.danger, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete rule',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏦', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Set up your first savings rule',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Savings rules automate your money habits — round up transactions, '
              'sweep surplus, or set fixed monthly transfers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Rule'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add Rule bottom sheet
// ---------------------------------------------------------------------------

class _AddRuleSheet extends StatefulWidget {
  const _AddRuleSheet({required this.onSaved});
  final ValueChanged<SavingsRuleModel> onSaved;

  @override
  State<_AddRuleSheet> createState() => _AddRuleSheetState();
}

class _AddRuleSheetState extends State<_AddRuleSheet> {
  String _selectedType = 'round_up';
  bool _isSaving = false;

  // round_up
  int _roundTo = 100;

  // surplus_sweep
  final _sweepPercentController = TextEditingController(text: '10');

  // fixed_monthly
  final _fixedAmountController = TextEditingController(text: '1000');

  // category_limit_alert
  List<CategoryModel> _categories = [];
  String? _selectedCategoryId;
  final _thresholdController = TextEditingController(text: '80');

  static const _types = [
    ('round_up', '🪙 Round Up'),
    ('surplus_sweep', '💸 Surplus Sweep'),
    ('fixed_monthly', '📅 Fixed Monthly'),
    ('category_limit_alert', '🔔 Category Alert'),
  ];

  static const _descriptions = {
    'round_up':
        'Every time you spend, the amount is rounded up to the nearest ₹ value. The difference goes to savings.',
    'surplus_sweep':
        'At month-end, a percentage of your unspent budget is automatically moved to savings.',
    'fixed_monthly':
        'A fixed amount is saved on the 1st of every month, like a standing instruction.',
    'category_limit_alert':
        'Receive an alert when a category budget reaches a set percentage — helping you stop overspending.',
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await AppServices.instance.categories.getAll();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _sweepPercentController.dispose();
    _fixedAmountController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildConfig() {
    return switch (_selectedType) {
      'round_up' => {'round_to': _roundTo},
      'surplus_sweep' => {
          'percent': int.tryParse(_sweepPercentController.text.trim()) ?? 10
        },
      'fixed_monthly' => {
          'amount': double.tryParse(_fixedAmountController.text.trim()) ?? 1000
        },
      'category_limit_alert' => {
          'threshold_percent':
              int.tryParse(_thresholdController.text.trim()) ?? 80
        },
      _ => {},
    };
  }

  Future<void> _save() async {
    if (_selectedType == 'category_limit_alert' && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final rule = await AppServices.instance.savingsRules.create(
        triggerType: _selectedType,
        categoryId: _selectedCategoryId,
        config: _buildConfig(),
      );
      widget.onSaved(rule);
      if (mounted) Navigator.of(context).pop();
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
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text('Add Savings Rule',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type selector
            const Text('Rule type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final selected = t.$1 == _selectedType;
                return FilterChip(
                  label: Text(t.$2, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() {
                    _selectedType = t.$1;
                    _selectedCategoryId = null;
                  }),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.primary,
                  side: BorderSide(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Description
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _descriptions[_selectedType] ?? '',
                style: const TextStyle(fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Config inputs
            _buildConfigInputs(),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save Rule'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigInputs() {
    return switch (_selectedType) {
      'round_up' => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Round to nearest ₹',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [50, 100, 500].map((v) {
                final selected = v == _roundTo;
                return ChoiceChip(
                  label: Text('₹$v'),
                  selected: selected,
                  onSelected: (_) => setState(() => _roundTo = v),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                );
              }).toList(),
            ),
          ],
        ),
      'surplus_sweep' => TextField(
          controller: _sweepPercentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sweep percentage (%)',
            hintText: 'e.g. 10',
            suffixText: '%',
            prefixIcon: Icon(Icons.percent_rounded),
          ),
        ),
      'fixed_monthly' => TextField(
          controller: _fixedAmountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monthly saving amount',
            prefixText: '₹ ',
            prefixIcon: Icon(Icons.currency_rupee_rounded),
          ),
        ),
      'category_limit_alert' => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_categories.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: _categories
                    .where((c) => c.type == 'EXPENSE')
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.icon}  ${c.name}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _thresholdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Alert threshold (%)',
                hintText: 'e.g. 80',
                suffixText: '%',
                prefixIcon: Icon(Icons.notifications_outlined),
              ),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
