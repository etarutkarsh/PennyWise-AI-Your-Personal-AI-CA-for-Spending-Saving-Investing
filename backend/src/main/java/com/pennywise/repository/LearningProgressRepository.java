package com.pennywise.repository;

import com.pennywise.entity.LearningProgress;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LearningProgressRepository extends JpaRepository<LearningProgress, UUID> {
    List<LearningProgress> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<LearningProgress> findByUserIdAndLessonId(UUID userId, String lessonId);
}
