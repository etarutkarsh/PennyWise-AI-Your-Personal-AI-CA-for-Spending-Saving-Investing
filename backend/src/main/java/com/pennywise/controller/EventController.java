package com.pennywise.controller;

import com.pennywise.entity.FinancialEvent;
import com.pennywise.service.EventQueryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/events")
@RequiredArgsConstructor
public class EventController {

    private final EventQueryService queryService;

    @GetMapping
    public ResponseEntity<List<FinancialEvent>> recent(@RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(queryService.recentEvents(Math.min(limit, 200)));
    }

    @GetMapping("/type/{eventType}")
    public ResponseEntity<List<FinancialEvent>> byType(@PathVariable String eventType) {
        return ResponseEntity.ok(queryService.eventsByType(eventType));
    }

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Long>> stats() {
        return ResponseEntity.ok(Map.of("totalEvents", queryService.totalEvents()));
    }
}
