import 'package:intl/intl.dart';
import 'goal_entity.dart';

// ─── Feasibility ──────────────────────────────────────────────────────────────

enum Feasibility { easy, doable, stretch, tough }

extension FeasibilityX on Feasibility {
  String get label {
    switch (this) {
      case Feasibility.easy:    return 'Easy';
      case Feasibility.doable:  return 'Doable';
      case Feasibility.stretch: return 'Stretch';
      case Feasibility.tough:   return 'Tough';
    }
  }

  String get description {
    switch (this) {
      case Feasibility.easy:
        return 'Well within your income — you can do this comfortably.';
      case Feasibility.doable:
        return 'Requires some discipline but achievable with your income.';
      case Feasibility.stretch:
        return 'Will need budget cuts or a slightly longer timeline.';
      case Feasibility.tough:
        return 'Consider extending the deadline or boosting income.';
    }
  }
}

// ─── GoalPlanContext ───────────────────────────────────────────────────────────
// This is the structured payload sent to the AI to generate a personalised plan.
// Call toAiPrompt() to build the message for POST /ai/chat.

class GoalPlanContext {
  final GoalEntity goal;
  final double monthlySalary;

  GoalPlanContext({required this.goal, required this.monthlySalary});

  // ── Derived computations ────────────────────────────────────────────────────

  int get monthsRemaining {
    final now = DateTime.now();
    final diff = goal.deadline.difference(now);
    return (diff.inDays / 30).ceil().clamp(1, 999);
  }

  double get remainingAmount =>
      (goal.targetAmount - goal.currentSaved).clamp(0, double.infinity);

  double get progressPercent => goal.targetAmount > 0
      ? (goal.currentSaved / goal.targetAmount * 100).clamp(0, 100)
      : 0;

  double get neededMonthly => goal.recommendedMonthlyContribution;

  double get estimatedSurplus => (monthlySalary * 0.30).clamp(0, double.infinity);

  Feasibility get feasibility {
    if (monthlySalary <= 0) return Feasibility.doable;
    final ratio = neededMonthly / monthlySalary;
    if (ratio < 0.20) return Feasibility.easy;
    if (ratio < 0.35) return Feasibility.doable;
    if (ratio < 0.50) return Feasibility.stretch;
    return Feasibility.tough;
  }

  bool get loanApplicable => [
    'house', 'car', 'education', 'wedding'
  ].contains(goal.goalType.toLowerCase());

  String get loanType {
    switch (goal.goalType.toLowerCase()) {
      case 'house': return 'Home Loan';
      case 'car':   return 'Car Loan';
      case 'education': return 'Education Loan';
      default: return 'Personal Loan';
    }
  }

  // Estimated EMI at 9% p.a. over 5 years for personal/wedding/car,
  // 20 years for home, 7 years for education.
  double get estimatedLoanEmi {
    final principal = remainingAmount;
    final years = goal.goalType.toLowerCase() == 'house'
        ? 20
        : goal.goalType.toLowerCase() == 'education'
            ? 7
            : 5;
    const rate = 9.0 / 100 / 12;
    final n = years * 12;
    if (principal <= 0 || n <= 0) return 0;
    final emi = principal * rate * (1 + rate).pow(n) / ((1 + rate).pow(n) - 1);
    return emi;
  }

  // ── AI Prompt ───────────────────────────────────────────────────────────────
  // Structured prompt sent to POST /ai/chat. PennyWise AI uses this to
  // generate a personalised achievement plan with milestones and product recs.

  String toAiPrompt() {
    final fmt = NumberFormat('#,##,###', 'en_IN');
    final dateFmt = DateFormat('d MMM yyyy');

    return '''
[PENNYWISE GOAL ACHIEVEMENT REQUEST]

Goal Summary:
- Name: ${goal.name}
- Type: ${goal.goalType}
- Target Amount: ₹${fmt.format(goal.targetAmount)}
- Currently Saved: ₹${fmt.format(goal.currentSaved)} (${progressPercent.toStringAsFixed(1)}%)
- Remaining: ₹${fmt.format(remainingAmount)}
- Deadline: ${dateFmt.format(goal.deadline)} ($monthsRemaining months from today)
- Priority: ${goal.investmentSuggestion.isNotEmpty ? goal.investmentSuggestion : 'medium'}

User Financial Profile:
- Monthly Income: ₹${fmt.format(monthlySalary)}
- Recommended Monthly Contribution: ₹${fmt.format(neededMonthly)}
- Estimated Monthly Surplus: ₹${fmt.format(estimatedSurplus)}
- Feasibility: ${feasibility.label} — ${feasibility.description}
- Backend Investment Suggestion: ${goal.investmentSuggestion}

Please generate a personalised achievement plan with:
1. SAVINGS PLAN — Monthly savings milestones, achievable targets, and 5 specific expense cuts to free up budget
2. INVESTMENT PLAN — Best products for this goal (SIP/RD/FD/gold), expected corpus, and a step-by-step monthly SIP schedule
3. ${loanApplicable ? 'LOAN ANALYSIS — $loanType eligibility, estimated EMI at 9% p.a., pros/cons vs saving/investing' : 'ALTERNATIVE PLAN — If the timeline is too tight, suggest an adjusted deadline and revised monthly target'}
4. QUICK WINS — 3 things the user can do THIS WEEK to start moving towards this goal

Format each section clearly. Use Indian Rupee amounts. Be specific, not generic.
''';
  }

  // ── JSON for future backend /goals/{id}/plan endpoint ───────────────────────

  Map<String, dynamic> toJson() => {
    'goal': {
      'id': goal.id,
      'name': goal.name,
      'type': goal.goalType,
      'targetAmount': goal.targetAmount,
      'currentSaved': goal.currentSaved,
      'deadline': goal.deadline.toIso8601String(),
      'monthsRemaining': monthsRemaining,
      'progressPercent': progressPercent,
      'recommendedMonthlyContribution': neededMonthly,
      'investmentSuggestion': goal.investmentSuggestion,
    },
    'userProfile': {
      'monthlyIncome': monthlySalary,
      'estimatedSurplus': estimatedSurplus,
      'feasibility': feasibility.name,
    },
    'loanApplicable': loanApplicable,
    'requestedPlans': ['savings', 'investment', loanApplicable ? 'loan' : 'alternative', 'quick_wins'],
  };
}

extension _NumPow on double {
  double pow(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= this;
    }
    return result;
  }
}
