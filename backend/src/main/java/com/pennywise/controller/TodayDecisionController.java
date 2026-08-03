package com.pennywise.controller;

import com.pennywise.dto.decision.TodayDecisionResponse;
import com.pennywise.service.TodayDecisionService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/decisions")
public class TodayDecisionController {

    private final TodayDecisionService todayDecisionService;

    public TodayDecisionController(TodayDecisionService todayDecisionService) {
        this.todayDecisionService = todayDecisionService;
    }

    @GetMapping("/today")
    public ResponseEntity<TodayDecisionResponse> getToday() {
        return ResponseEntity.ok(todayDecisionService.compute());
    }
}
