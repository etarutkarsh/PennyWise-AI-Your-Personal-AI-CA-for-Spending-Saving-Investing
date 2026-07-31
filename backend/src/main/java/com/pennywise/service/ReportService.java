package com.pennywise.service;

import com.pennywise.dto.ReportDto;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.TransactionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ReportService {

    private final TransactionRepository transactionRepository;
    private final CurrentUserProvider currentUserProvider;

    public ReportDto monthlyReport(int year, int month) {
        User user = currentUserProvider.get();

        YearMonth ym = YearMonth.of(year, month);
        Instant from = ym.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to   = ym.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);

        List<Transaction> txns = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), from, to);

        BigDecimal totalSpend  = BigDecimal.ZERO;
        BigDecimal totalIncome = BigDecimal.ZERO;

        Map<String, BigDecimal> spendByCategory = new java.util.LinkedHashMap<>();
        Map<String, String>     iconByCategory  = new java.util.LinkedHashMap<>();

        for (Transaction t : txns) {
            if (t.getDirection() == Transaction.TransactionDirection.DEBIT) {
                totalSpend = totalSpend.add(t.getAmount());
                String cat  = t.getCategory() != null ? t.getCategory().getName() : "Uncategorized";
                String icon = t.getCategory() != null ? t.getCategory().getIcon() : "💸";
                spendByCategory.merge(cat, t.getAmount(), BigDecimal::add);
                iconByCategory.putIfAbsent(cat, icon);
            } else {
                totalIncome = totalIncome.add(t.getAmount());
            }
        }

        final BigDecimal spend = totalSpend;
        List<ReportDto.CategorySpend> byCategory = spendByCategory.entrySet().stream()
                .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                .map(e -> {
                    double pct = spend.compareTo(BigDecimal.ZERO) == 0 ? 0.0
                            : e.getValue().divide(spend, 4, RoundingMode.HALF_UP)
                               .multiply(BigDecimal.valueOf(100))
                               .doubleValue();
                    return ReportDto.CategorySpend.builder()
                            .categoryName(e.getKey())
                            .categoryIcon(iconByCategory.getOrDefault(e.getKey(), "💸"))
                            .amount(e.getValue())
                            .percentage(pct)
                            .build();
                })
                .collect(Collectors.toList());

        return ReportDto.builder()
                .period(ym.toString())
                .totalSpend(totalSpend)
                .totalIncome(totalIncome)
                .netSavings(totalIncome.subtract(totalSpend))
                .byCategory(byCategory)
                .build();
    }

    public List<ReportDto> last6Months() {
        List<ReportDto> reports = new ArrayList<>();
        YearMonth current = YearMonth.now();
        for (int i = 0; i < 6; i++) {
            YearMonth ym = current.minusMonths(i);
            reports.add(monthlyReport(ym.getYear(), ym.getMonthValue()));
        }
        return reports;
    }
}
