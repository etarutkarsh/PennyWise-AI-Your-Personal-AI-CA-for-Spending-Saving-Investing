package com.pennywise.controller;

import com.pennywise.dto.NotificationDto;
import com.pennywise.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    private final NotificationService notificationService;

    public NotificationController(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @GetMapping
    public List<NotificationDto> list() {
        return notificationService.listForCurrentUser();
    }

    @PatchMapping("/{id}/read")
    public NotificationDto markRead(@PathVariable UUID id) {
        return notificationService.markRead(id);
    }

    @PostMapping("/read-all")
    public ResponseEntity<Void> markAllRead() {
        notificationService.markAllRead();
        return ResponseEntity.noContent().build();
    }
}
