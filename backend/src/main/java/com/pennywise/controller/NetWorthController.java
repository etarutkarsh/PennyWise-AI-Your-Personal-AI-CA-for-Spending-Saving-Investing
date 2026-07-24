package com.pennywise.controller;

import com.pennywise.dto.*;
import com.pennywise.service.NetWorthService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/net-worth")
public class NetWorthController {

    private final NetWorthService netWorthService;

    public NetWorthController(NetWorthService netWorthService) {
        this.netWorthService = netWorthService;
    }

    @GetMapping("/summary")
    public NetWorthSummaryDto getSummary() {
        return netWorthService.getSummary();
    }

    @PostMapping("/assets")
    @ResponseStatus(HttpStatus.CREATED)
    public AssetDto createAsset(@RequestBody AssetCreateRequest request) {
        return netWorthService.createAsset(request);
    }

    @DeleteMapping("/assets/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteAsset(@PathVariable UUID id) {
        netWorthService.deleteAsset(id);
    }

    @PostMapping("/liabilities")
    @ResponseStatus(HttpStatus.CREATED)
    public LiabilityDto createLiability(@RequestBody LiabilityCreateRequest request) {
        return netWorthService.createLiability(request);
    }

    @DeleteMapping("/liabilities/{id}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void deleteLiability(@PathVariable UUID id) {
        netWorthService.deleteLiability(id);
    }
}
