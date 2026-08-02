package com.pennywise.controller;

import com.pennywise.dto.BudgetCreateRequest;
import com.pennywise.dto.BudgetDto;
import com.pennywise.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/budgets")
public class BudgetController {

    private final BudgetService budgetService;

    public BudgetController(BudgetService budgetService) {
        this.budgetService = budgetService;
    }

    @PostMapping
    public ResponseEntity<BudgetDto> create(@Valid @RequestBody BudgetCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(budgetService.create(request));
    }

    @GetMapping
    public List<BudgetDto> listCurrentPeriod() {
        return budgetService.listForCurrentPeriod();
    }

    @PatchMapping("/{id}")
    public BudgetDto update(@PathVariable UUID id, @RequestBody java.util.Map<String, BigDecimal> body) {
        return budgetService.update(id, body.get("monthlyLimit"));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        budgetService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
