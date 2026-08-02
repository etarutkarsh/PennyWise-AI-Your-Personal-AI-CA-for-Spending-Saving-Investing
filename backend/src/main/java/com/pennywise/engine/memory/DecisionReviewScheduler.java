package com.pennywise.engine.memory;

import org.springframework.stereotype.Component;
import java.time.LocalDate;
import java.util.Map;

@Component
public class DecisionReviewScheduler {

    // keyword → review months
    private static final Map<String, Integer> REVIEW_MONTHS = Map.ofEntries(
        Map.entry("house", 12), Map.entry("flat", 12), Map.entry("apartment", 12), Map.entry("property", 12),
        Map.entry("car", 6), Map.entry("bike", 6), Map.entry("vehicle", 6),
        Map.entry("laptop", 3), Map.entry("macbook", 3), Map.entry("computer", 3),
        Map.entry("phone", 3), Map.entry("iphone", 3), Map.entry("mobile", 3),
        Map.entry("tv", 3), Map.entry("tablet", 3), Map.entry("ipad", 3),
        Map.entry("investment", 12), Map.entry("fund", 12), Map.entry("sip", 12), Map.entry("stocks", 12),
        Map.entry("vacation", 2), Map.entry("trip", 2), Map.entry("travel", 2),
        Map.entry("wedding", 12), Map.entry("marriage", 12),
        Map.entry("education", 6), Map.entry("course", 3), Map.entry("mba", 12)
    );

    public LocalDate reviewDateFor(String itemName) {
        if (itemName == null) return LocalDate.now().plusMonths(6);
        String lower = itemName.toLowerCase();
        int months = REVIEW_MONTHS.entrySet().stream()
            .filter(e -> lower.contains(e.getKey()))
            .mapToInt(Map.Entry::getValue)
            .findFirst()
            .orElse(6);
        return LocalDate.now().plusMonths(months);
    }
}
