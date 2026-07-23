package com.pennywise.controller;

import com.pennywise.dto.InvestmentPortfolioCreateRequest;
import com.pennywise.dto.InvestmentPortfolioDto;
import com.pennywise.service.InvestmentPortfolioService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/investments")
public class InvestmentPortfolioController {

    private final InvestmentPortfolioService service;

    public InvestmentPortfolioController(InvestmentPortfolioService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<InvestmentPortfolioDto>> list() {
        return ResponseEntity.ok(service.listForCurrentUser());
    }

    @PostMapping
    public ResponseEntity<InvestmentPortfolioDto> create(
            @RequestBody InvestmentPortfolioCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.create(request));
    }

    @PatchMapping("/{id}/current-value")
    public ResponseEntity<InvestmentPortfolioDto> updateCurrentValue(
            @PathVariable UUID id,
            @RequestBody Map<String, BigDecimal> body) {
        return ResponseEntity.ok(service.updateCurrentValue(id, body.get("currentValue")));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}
