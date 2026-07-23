package com.pennywise.repository;

import com.pennywise.entity.Goal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface GoalRepository extends JpaRepository<Goal, UUID> {

    List<Goal> findByUserIdOrderByDeadlineAsc(UUID userId);
}
