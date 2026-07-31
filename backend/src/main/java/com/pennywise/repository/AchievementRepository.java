package com.pennywise.repository;

import com.pennywise.entity.Achievement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AchievementRepository extends JpaRepository<Achievement, UUID> {
    List<Achievement> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<Achievement> findByUserIdAndCode(UUID userId, String code);
}
