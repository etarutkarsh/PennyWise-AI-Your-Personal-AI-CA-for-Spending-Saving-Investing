package com.pennywise.controller;

import com.pennywise.dto.memory.*;
import com.pennywise.service.DecisionMemoryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/decision-memory")
@RequiredArgsConstructor
public class DecisionMemoryController {

    private final DecisionMemoryService service;

    @GetMapping
    public ResponseEntity<List<DecisionMemoryDto>> listAll() {
        return ResponseEntity.ok(service.listAll());
    }

    @GetMapping("/timeline")
    public ResponseEntity<List<TimelineEntryDto>> timeline() {
        return ResponseEntity.ok(service.timeline());
    }

    @GetMapping("/pending-reviews")
    public ResponseEntity<List<DecisionMemoryDto>> pendingReviews() {
        return ResponseEntity.ok(service.pendingReviews());
    }

    @GetMapping("/insights")
    public ResponseEntity<InsightsDto> insights() {
        return ResponseEntity.ok(service.insights());
    }

    @GetMapping("/{id}")
    public ResponseEntity<DecisionMemoryDto> getById(@PathVariable UUID id) {
        return ResponseEntity.ok(service.getById(id));
    }

    @PostMapping("/{id}/review")
    public ResponseEntity<DecisionOutcomeDto> submitReview(
            @PathVariable UUID id, @RequestBody ReviewRequest req) {
        return ResponseEntity.ok(service.submitReview(id, req));
    }
}
