package com.pennywise.controller;

import com.pennywise.dto.twin.DigitalTwinDto;
import com.pennywise.service.DigitalTwinService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller exposing the Financial Digital Twin engine.
 *
 * <p>GET  /twin         — returns the current user's twin (lazy recompute if stale)
 * <p>POST /twin/refresh — forces immediate recomputation
 */
@RestController
@RequestMapping("/twin")
@RequiredArgsConstructor
public class DigitalTwinController {

    private final DigitalTwinService digitalTwinService;

    @GetMapping
    public ResponseEntity<DigitalTwinDto> getTwin() {
        return ResponseEntity.ok(digitalTwinService.getTwin());
    }

    @PostMapping("/refresh")
    public ResponseEntity<DigitalTwinDto> refreshTwin() {
        return ResponseEntity.ok(digitalTwinService.refreshTwin());
    }
}
