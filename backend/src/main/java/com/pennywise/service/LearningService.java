package com.pennywise.service;

import com.pennywise.dto.AchievementDto;
import com.pennywise.dto.LearningProgressDto;
import com.pennywise.entity.Achievement;
import com.pennywise.entity.LearningProgress;
import com.pennywise.entity.User;
import com.pennywise.repository.AchievementRepository;
import com.pennywise.repository.LearningProgressRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class LearningService {

    private final LearningProgressRepository progressRepository;
    private final AchievementRepository achievementRepository;
    private final CurrentUserProvider currentUserProvider;

    private static final Map<String, String> LESSON_ACHIEVEMENT = Map.of(
            "salary_basics",     "salary_quiz_done",
            "savings_basics",    "savings_quiz_done",
            "investment_basics", "investment_quiz_done",
            "budget_basics",     "budget_quiz_done"
    );

    private static final Map<String, String> ACHIEVEMENT_TITLES = Map.of(
            "salary_quiz_done",     "💰 Salary Scholar",
            "savings_quiz_done",    "🏦 Savings Expert",
            "investment_quiz_done", "📈 Investment Pro",
            "budget_quiz_done",     "🎯 Budget Boss",
            "onboarding_complete",  "🎉 Onboarding Complete"
    );

    public List<LearningProgressDto> getProgress() {
        User user = currentUserProvider.get();
        return progressRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public LearningProgressDto completeLesson(String topic, String lessonId, Integer quizScore) {
        User user = currentUserProvider.get();

        LearningProgress progress = progressRepository
                .findByUserIdAndLessonId(user.getId(), lessonId)
                .orElseGet(() -> {
                    LearningProgress p = new LearningProgress();
                    p.setUserId(user.getId());
                    p.setTopic(topic);
                    p.setLessonId(lessonId);
                    return p;
                });

        progress.setCompleted(true);
        progress.setQuizScore(quizScore);
        progress.setCompletedAt(Instant.now());
        progressRepository.save(progress);

        String achievementCode = LESSON_ACHIEVEMENT.get(lessonId);
        if (achievementCode != null) {
            unlockAchievement(user.getId(), achievementCode);
        }

        return toDto(progress);
    }

    @Transactional
    public AchievementDto unlockAchievement(UUID userId, String code) {
        return achievementRepository.findByUserIdAndCode(userId, code)
                .map(this::toAchievementDto)
                .orElseGet(() -> {
                    Achievement a = new Achievement();
                    a.setUserId(userId);
                    a.setCode(code);
                    a.setTitle(ACHIEVEMENT_TITLES.getOrDefault(code, code));
                    return toAchievementDto(achievementRepository.save(a));
                });
    }

    @Transactional
    public AchievementDto unlockAchievementForCurrentUser(String code) {
        User user = currentUserProvider.get();
        return unlockAchievement(user.getId(), code);
    }

    public List<AchievementDto> getAchievements() {
        User user = currentUserProvider.get();
        return achievementRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toAchievementDto)
                .toList();
    }

    public int getTotalXp() {
        User user = currentUserProvider.get();
        return progressRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .filter(LearningProgress::isCompleted)
                .mapToInt(p -> p.getQuizScore() != null ? p.getQuizScore() : 0)
                .sum();
    }

    private LearningProgressDto toDto(LearningProgress p) {
        return LearningProgressDto.builder()
                .id(p.getId())
                .topic(p.getTopic())
                .lessonId(p.getLessonId())
                .completed(p.isCompleted())
                .quizScore(p.getQuizScore())
                .completedAt(p.getCompletedAt())
                .build();
    }

    private AchievementDto toAchievementDto(Achievement a) {
        return AchievementDto.builder()
                .id(a.getId())
                .code(a.getCode())
                .title(a.getTitle())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
