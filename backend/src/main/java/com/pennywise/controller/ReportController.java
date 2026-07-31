package com.pennywise.controller;

import com.pennywise.dto.ReportDto;
import com.pennywise.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {

    private final ReportService reportService;

    /** GET /reports/monthly?year=2025&month=7 */
    @GetMapping("/monthly")
    public ResponseEntity<ReportDto> monthly(
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        YearMonth now = YearMonth.now();
        int y = year  != null ? year  : now.getYear();
        int m = month != null ? month : now.getMonthValue();
        return ResponseEntity.ok(reportService.monthlyReport(y, m));
    }

    /** GET /reports/trend — last 6 months for sparkline charts */
    @GetMapping("/trend")
    public ResponseEntity<List<ReportDto>> trend() {
        return ResponseEntity.ok(reportService.last6Months());
    }
}
