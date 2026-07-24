import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_services.dart';
import '../../../../core/services/storage/user_prefs_storage.dart';

/// Last step of the User Journey (PRD Section 6): Signup -> Salary ->
/// Bank Connection -> SMS Permission -> Goal Setup -> Dashboard.
/// This screen collects salary + first goal before dropping the user
/// into the main app shell.
class OnboardingGoalSetupScreen extends StatefulWidget {
  const OnboardingGoalSetupScreen({super.key});

  @override
  State<OnboardingGoalSetupScreen> createState() => _OnboardingGoalSetupScreenState();
}

class _OnboardingGoalSetupScreenState extends State<OnboardingGoalSetupScreen> {
  final _salaryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final salary = double.tryParse(_salaryController.text.replaceAll(',', '')) ?? 50000.0;
    await UserPrefsStorage.saveSalary(salary);
    await UserPrefsStorage.addAchievement('onboarding_complete');
    try {
      await AppServices.instance.user.updateMe(monthlyIncome: salary);
    } catch (_) {}
    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Let\'s set you up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "What's your monthly take-home income?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text(
                'This is the amount credited to your bank after all deductions (PF, tax, etc.)',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salaryController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly take-home salary',
                  prefixText: '₹ ',
                  hintText: 'e.g. 50000',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your salary';
                  final parsed = double.tryParse(v.replaceAll(',', ''));
                  if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'You can grant SMS/notification access and set your first goal '
                'from Settings and the Goals tab at any time.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : _onContinue,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
