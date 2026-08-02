package com.pennywise.controller;

import com.pennywise.dto.behavior.BehaviorProfileDto;
import com.pennywise.service.BehaviorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller exposing the Behavioral Engine.
 * <p>
 * GET  /behavior         — returns the current user's behavioral profile (lazy recompute if stale)
 * POST /behavior/refresh — forces immediate recomputation
 */
@RestController
@RequestMapping("/behavior")
@RequiredArgsConstructor
public class BehaviorController {

    private final BehaviorService behaviorService;

    @GetMapping
    public ResponseEntity<BehaviorProfileDto> getProfile() {
        return ResponseEntity.ok(behaviorService.getProfile());
    }

    @PostMapping("/refresh")
    public ResponseEntity<BehaviorProfileDto> refresh() {
        return ResponseEntity.ok(behaviorService.recomputeProfile());
    }
}
