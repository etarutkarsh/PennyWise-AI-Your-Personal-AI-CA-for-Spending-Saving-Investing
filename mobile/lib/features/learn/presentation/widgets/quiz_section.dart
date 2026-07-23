import 'package:flutter/material.dart';

import '../../../../core/services/storage/user_prefs_storage.dart';
import '../../../../core/theme/app_colors.dart';

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}

class QuizSection extends StatefulWidget {
  final String quizId;
  final String title;
  final List<QuizQuestion> questions;
  final void Function(int score, int total) onCompleted;

  const QuizSection({
    super.key,
    required this.quizId,
    required this.title,
    required this.questions,
    required this.onCompleted,
  });

  @override
  State<QuizSection> createState() => _QuizSectionState();
}

class _QuizSectionState extends State<QuizSection> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOption;
  bool _answered = false;
  bool _completed = false;
  bool _alreadyCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyCompleted();
  }

  Future<void> _checkIfAlreadyCompleted() async {
    final completed = await UserPrefsStorage.getCompletedQuizzes();
    if (mounted && completed.contains(widget.quizId)) {
      setState(() => _alreadyCompleted = true);
    }
  }

  void _selectOption(int index) {
    if (_answered) return;
    setState(() {
      _selectedOption = index;
      _answered = true;
      if (index == widget.questions[_currentIndex].correctIndex) {
        _score++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _answered = false;
      });
    } else {
      await UserPrefsStorage.addQuizScore(_score * 10);
      await UserPrefsStorage.markQuizCompleted(widget.quizId);
      setState(() => _completed = true);
      widget.onCompleted(_score, widget.questions.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadyCompleted) return _buildAlreadyCompletedCard();
    if (_completed) return _buildCompletionCard();

    final q = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_outlined, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Q${_currentIndex + 1}/${widget.questions.length}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Text(
            q.question,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.4),
          ),
        ),
        const SizedBox(height: 12),
        ...q.options.asMap().entries.map(
          (e) => _OptionTile(
            text: e.value,
            letter: String.fromCharCode(65 + e.key),
            isSelected: _selectedOption == e.key,
            isCorrect: e.key == q.correctIndex,
            isAnswered: _answered,
            onTap: () => _selectOption(e.key),
          ),
        ),
        if (_answered) ...[
          const SizedBox(height: 12),
          _ExplanationBox(
            isCorrect: _selectedOption == q.correctIndex,
            explanation: q.explanation,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex < widget.questions.length - 1
                    ? 'Next Question →'
                    : 'See My Results',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompletionCard() {
    final percent = (_score / widget.questions.length * 100).round();
    final isPerf = percent == 100;
    final isGood = percent >= 60;
    final emoji = isPerf ? '🏆' : isGood ? '🎯' : '📚';
    final message = isPerf
        ? 'Perfect score! You\'re a financial wizard! 🌟'
        : isGood
            ? 'Great job! Keep learning to level up!'
            : 'Good try! Review the content and retake later.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.success.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            '$_score / ${widget.questions.length} Correct!',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              '+${_score * 10} XP earned! ⚡',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.accent,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyCompletedCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Already Completed! ✅',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'You\'ve aced this quiz. Come back tomorrow for new challenges!',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String text;
  final String letter;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  const _OptionTile({
    required this.text,
    required this.letter,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    Color bgColor;
    Color letterBg;
    Color letterText;

    if (!isAnswered) {
      borderColor = Colors.grey.withOpacity(0.3);
      bgColor = Colors.transparent;
      letterBg = AppColors.background;
      letterText = AppColors.textSecondary;
    } else if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withOpacity(0.08);
      letterBg = AppColors.success;
      letterText = Colors.white;
    } else if (isSelected) {
      borderColor = AppColors.danger;
      bgColor = AppColors.danger.withOpacity(0.07);
      letterBg = AppColors.danger;
      letterText = Colors.white;
    } else {
      borderColor = Colors.grey.withOpacity(0.2);
      bgColor = Colors.transparent;
      letterBg = AppColors.background;
      letterText = AppColors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: isAnswered ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: (isAnswered && (isCorrect || isSelected)) ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(color: letterBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: letterText,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isAnswered && isCorrect
                        ? AppColors.success
                        : isAnswered && isSelected
                            ? AppColors.danger
                            : AppColors.textPrimary,
                    fontWeight:
                        isAnswered && (isCorrect || isSelected) ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isAnswered && isCorrect)
                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
              if (isAnswered && isSelected && !isCorrect)
                const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool isCorrect;
  final String explanation;

  const _ExplanationBox({required this.isCorrect, required this.explanation});

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.warning;
    final icon = isCorrect ? Icons.lightbulb_rounded : Icons.info_outline_rounded;
    final label = isCorrect ? '🎉 Correct!' : '💡 Learn This';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(explanation, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
