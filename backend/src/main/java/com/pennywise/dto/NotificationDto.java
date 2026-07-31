package com.pennywise.dto;

import lombok.Builder;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
public class NotificationDto {
    private UUID id;
    private String type;
    private String title;
    private String body;
    private boolean read;
    private Instant createdAt;
}
