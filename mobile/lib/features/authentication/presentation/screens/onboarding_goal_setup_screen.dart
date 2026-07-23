import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Let\'s set you up')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("What's your monthly take-home income?"),
            const SizedBox(height: 12),
            TextField(
              controller: _salaryController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Monthly income', prefixText: '₹ '),
            ),
            const SizedBox(height: 24),
            const Text('You can grant SMS/notification access and set your first goal '
                'from Settings and the Goals tab at any time.'),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // TODO: PATCH /users/me with monthlyIncome, then mark onboardingComplete.
                context.go('/dashboard');
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
