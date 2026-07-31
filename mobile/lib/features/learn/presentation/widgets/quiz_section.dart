import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/services/app_services.dart';
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
      final xp = _score * 10;
      await UserPrefsStorage.addQuizScore(xp);
      await UserPrefsStorage.markQuizCompleted(widget.quizId);
      setState(() => _completed = true);
      widget.onCompleted(_score, widget.questions.length);
      // Sync to backend in the background — local storage remains source of
      // truth so any network failure is silent.
      AppServices.instance.learning
          .completeLesson(widget.quizId, xp)
          .catchError((_) {});
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(Icons.quiz_outlined, color: AppColors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.title,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Q${_currentIndex + 1}/${widget.questions.length}',
                style: GoogleFonts.dmSans(
                  color: AppColors.orange,
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
            backgroundColor: AppColors.border,
            valueColor: const AlwaysStoppedAnimation(AppColors.orange),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: AppColors.orange),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        q.question,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _nextQuestion,
              child: Text(
                _currentIndex < widget.questions.length - 1
                    ? 'Next Question →'
                    : 'See My Results',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
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
            AppColors.success.withValues(alpha: 0.12),
            AppColors.orange.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 8),
          Text(
            '$_score / ${widget.questions.length} Correct!',
            style: GoogleFonts.dmSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: Text(
              '+${_score * 10} XP earned! ⚡',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w800,
                color: AppColors.amber,
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
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quiz Already Completed! ✅',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You\'ve aced this quiz. Come back tomorrow for new challenges!',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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
    Color textColor;

    if (!isAnswered) {
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      letterBg = AppColors.surfaceElevated;
      letterText = AppColors.textSecondary;
      textColor = AppColors.textPrimary;
    } else if (isCorrect) {
      borderColor = AppColors.success;
      bgColor = AppColors.success.withValues(alpha: 0.10);
      letterBg = AppColors.success;
      letterText = Colors.white;
      textColor = AppColors.success;
    } else if (isSelected) {
      borderColor = AppColors.danger;
      bgColor = AppColors.danger.withValues(alpha: 0.10);
      letterBg = AppColors.danger;
      letterText = Colors.white;
      textColor = AppColors.danger;
    } else {
      borderColor = AppColors.border;
      bgColor = AppColors.surface;
      letterBg = AppColors.surfaceElevated;
      letterText = AppColors.textSecondary;
      textColor = AppColors.textSecondary;
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
                  style: GoogleFonts.dmSans(
                    color: textColor,
                    fontWeight: (isAnswered && (isCorrect || isSelected))
                        ? FontWeight.w600
                        : FontWeight.normal,
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
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
