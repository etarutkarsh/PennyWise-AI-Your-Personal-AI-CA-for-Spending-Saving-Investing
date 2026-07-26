package com.pennywise.controller;

import com.pennywise.dto.FinancialGraphResponse;
import com.pennywise.service.FinancialGraphService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/dashboard/graph")
public class FinancialGraphController {

    private final FinancialGraphService graphService;

    public FinancialGraphController(FinancialGraphService graphService) {
        this.graphService = graphService;
    }

    @GetMapping
    public FinancialGraphResponse getGraph() {
        return graphService.build();
    }
}
