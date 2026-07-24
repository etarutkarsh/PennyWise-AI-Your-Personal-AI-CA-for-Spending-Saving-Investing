package com.pennywise.controller;

import com.pennywise.dto.SavingsRuleCreateRequest;
import com.pennywise.dto.SavingsRuleDto;
import com.pennywise.service.SavingsRuleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/savings-rules")
public class SavingsRuleController {

    private final SavingsRuleService savingsRuleService;

    public SavingsRuleController(SavingsRuleService savingsRuleService) {
        this.savingsRuleService = savingsRuleService;
    }

    @GetMapping
    public List<SavingsRuleDto> list() {
        return savingsRuleService.getAll();
    }

    @PostMapping
    public ResponseEntity<SavingsRuleDto> create(@Valid @RequestBody SavingsRuleCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(savingsRuleService.create(request));
    }

    @PatchMapping("/{id}/toggle")
    public SavingsRuleDto toggle(@PathVariable UUID id) {
        return savingsRuleService.toggleActive(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        savingsRuleService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
