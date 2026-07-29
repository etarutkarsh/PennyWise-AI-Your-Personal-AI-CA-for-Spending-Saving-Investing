package com.pennywise.service;

import com.pennywise.dto.BudgetCreateRequest;
import com.pennywise.dto.BudgetDto;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Category;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.CategoryRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.List;

@Service
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final TransactionRepository transactionRepository;
    private final CurrentUserProvider currentUserProvider;

    public BudgetService(BudgetRepository budgetRepository,
                          CategoryRepository categoryRepository,
                          TransactionRepository transactionRepository,
                          CurrentUserProvider currentUserProvider) {
        this.budgetRepository = budgetRepository;
        this.categoryRepository = categoryRepository;
        this.transactionRepository = transactionRepository;
        this.currentUserProvider = currentUserProvider;
    }

    @Transactional
    public BudgetDto create(BudgetCreateRequest request) {
        User user = currentUserProvider.get();
        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Category not found"));

        Budget budget = new Budget();
        budget.setUserId(user.getId());
        budget.setCategory(category);
        budget.setMonthlyLimit(request.getMonthlyLimit());
        budget.setPeriod(request.getPeriod() != null ? request.getPeriod() : YearMonth.now().toString());
        if (request.getAlertThresholdPercent() != null) {
            budget.setAlertThresholdPercent(request.getAlertThresholdPercent());
        }

        return toDto(budgetRepository.save(budget));
    }

    public List<BudgetDto> listForCurrentPeriod() {
        User user = currentUserProvider.get();
        YearMonth ym = YearMonth.now();
        String period = ym.toString();
        Instant from = ym.atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();
        Instant to = ym.plusMonths(1).atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();

        return budgetRepository.findByUserIdAndPeriod(user.getId(), period)
                .stream().map(b -> {
                    BigDecimal spent = transactionRepository.sumByCategoryAndPeriod(
                            user.getId(), b.getCategory().getId(), from, to);
                    b.setSpentSoFar(spent);
                    return toDto(b);
                }).toList();
    }

    private BudgetDto toDto(Budget b) {
        BigDecimal remaining = b.getMonthlyLimit().subtract(b.getSpentSoFar());
        double percentUsed = b.getMonthlyLimit().compareTo(BigDecimal.ZERO) > 0
                ? b.getSpentSoFar().divide(b.getMonthlyLimit(), 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).doubleValue()
                : 0.0;

        return BudgetDto.builder()
                .id(b.getId())
                .categoryId(b.getCategory().getId())
                .categoryName(b.getCategory().getName())
                .categoryIcon(b.getCategory().getIcon())
                .monthlyLimit(b.getMonthlyLimit())
                .spentSoFar(b.getSpentSoFar())
                .remaining(remaining)
                .percentUsed(percentUsed)
                .period(b.getPeriod())
                .overBudget(remaining.compareTo(BigDecimal.ZERO) < 0)
                .build();
    }
}
