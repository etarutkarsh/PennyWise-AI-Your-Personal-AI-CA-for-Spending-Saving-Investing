package com.pennywise.controller;

import com.pennywise.dto.GoalCreateRequest;
import com.pennywise.dto.GoalDto;
import com.pennywise.service.GoalService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/goals")
public class GoalController {

    private final GoalService goalService;

    public GoalController(GoalService goalService) {
        this.goalService = goalService;
    }

    @PostMapping
    public ResponseEntity<GoalDto> create(@Valid @RequestBody GoalCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(goalService.create(request));
    }

    @GetMapping
    public List<GoalDto> list() {
        return goalService.listForCurrentUser();
    }

    @PatchMapping("/{id}/saved-amount")
    public GoalDto updateSavedAmount(@PathVariable UUID id, @RequestBody @NotNull BigDecimal amount) {
        return goalService.updateSavedAmount(id, amount);
    }
}
