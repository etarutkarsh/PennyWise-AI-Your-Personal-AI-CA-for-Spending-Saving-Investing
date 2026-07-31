package com.pennywise.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class AchievementDto {
    private UUID id;
    private String code;
    private String title;
    private Instant createdAt;
}
