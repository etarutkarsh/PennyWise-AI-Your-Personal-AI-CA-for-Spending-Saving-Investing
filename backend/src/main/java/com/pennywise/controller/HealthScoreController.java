package com.pennywise.controller;

import com.pennywise.dto.HealthScoreResponse;
import com.pennywise.service.HealthScoreService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dashboard")
public class HealthScoreController {

    private final HealthScoreService healthScoreService;

    public HealthScoreController(HealthScoreService healthScoreService) {
        this.healthScoreService = healthScoreService;
    }

    @GetMapping("/health-score")
    public ResponseEntity<HealthScoreResponse> getHealthScore() {
        return ResponseEntity.ok(healthScoreService.calculate());
    }
}
