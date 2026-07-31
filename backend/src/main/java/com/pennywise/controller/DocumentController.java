package com.pennywise.controller;

import com.pennywise.dto.DocumentCreateRequest;
import com.pennywise.dto.DocumentDto;
import com.pennywise.service.DocumentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

/** Phase 3 — Financial Vault: document upload, OCR, and verification lifecycle. */
@RestController
@RequestMapping("/documents")
public class DocumentController {

    private final DocumentService documentService;

    public DocumentController(DocumentService documentService) {
        this.documentService = documentService;
    }

    @PostMapping
    public ResponseEntity<DocumentDto> create(@Valid @RequestBody DocumentCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(documentService.create(request));
    }

    @GetMapping
    public List<DocumentDto> list(@RequestParam(required = false) String type) {
        if (type != null) return documentService.listByType(type);
        return documentService.listForCurrentUser();
    }

    @PatchMapping("/{id}/verify")
    public DocumentDto verify(@PathVariable UUID id) {
        return documentService.verify(id);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable UUID id) {
        documentService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
