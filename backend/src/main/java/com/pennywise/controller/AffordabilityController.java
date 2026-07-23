package com.pennywise.controller;

import com.pennywise.dto.AffordabilityRequest;
import com.pennywise.dto.AffordabilityResponse;
import com.pennywise.service.AffordabilityService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Feature 4 - Affordability Checker: "Can I actually afford this?" */
@RestController
@RequestMapping("/affordability")
public class AffordabilityController {

    private final AffordabilityService affordabilityService;

    public AffordabilityController(AffordabilityService affordabilityService) {
        this.affordabilityService = affordabilityService;
    }

    @PostMapping("/check")
    public AffordabilityResponse check(@Valid @RequestBody AffordabilityRequest request) {
        return affordabilityService.check(request);
    }
}
