package com.pennywise.controller;

import com.pennywise.dto.TransactionCreateRequest;
import com.pennywise.dto.TransactionDto;
import com.pennywise.dto.TransactionUpdateRequest;
import com.pennywise.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/transactions")
public class TransactionController {

    private final TransactionService transactionService;

    public TransactionController(TransactionService transactionService) {
        this.transactionService = transactionService;
    }

    @PostMapping
    public ResponseEntity<TransactionDto> create(@Valid @RequestBody TransactionCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(transactionService.create(request));
    }

    @GetMapping
    public ResponseEntity<List<TransactionDto>> list(
            @RequestParam(required = false) String direction,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search) {
        return ResponseEntity.ok(transactionService.listFiltered(direction, category, search));
    }

    @PatchMapping("/{id}")
    public ResponseEntity<TransactionDto> update(
            @PathVariable UUID id,
            @RequestBody TransactionUpdateRequest req) {
        return ResponseEntity.ok(transactionService.update(id, req));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        transactionService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
