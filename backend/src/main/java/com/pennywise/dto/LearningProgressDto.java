package com.pennywise.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class LearningProgressDto {
    private UUID id;
    private String topic;
    private String lessonId;
    private boolean completed;
    private Integer quizScore;
    private Instant completedAt;
}
