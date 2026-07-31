package com.pennywise.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@Table(name = "learning_progress",
       uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "lesson_id"}))
public class LearningProgress extends BaseEntity {

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(nullable = false)
    private String topic;

    @Column(name = "lesson_id", nullable = false)
    private String lessonId;

    private boolean completed = false;

    private Integer quizScore;

    private Instant completedAt;
}
