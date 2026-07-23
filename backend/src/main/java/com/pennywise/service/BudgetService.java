package com.pennywise.service;

import com.pennywise.dto.BudgetCreateRequest;
import com.pennywise.dto.BudgetDto;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Category;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.CategoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.YearMonth;
import java.util.List;

@Service
public class BudgetService {

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentUserProvider currentUserProvider;

    public BudgetService(BudgetRepository budgetRepository,
                          CategoryRepository categoryRepository,
                          CurrentUserProvider currentUserProvider) {
        this.budgetRepository = budgetRepository;
        this.categoryRepository = categoryRepository;
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
        String period = YearMonth.now().toString();
        return budgetRepository.findByUserIdAndPeriod(user.getId(), period)
                .stream().map(this::toDto).toList();
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
                .monthlyLimit(b.getMonthlyLimit())
                .spentSoFar(b.getSpentSoFar())
                .remaining(remaining)
                .percentUsed(percentUsed)
                .period(b.getPeriod())
                .overBudget(remaining.compareTo(BigDecimal.ZERO) < 0)
                .build();
    }
}
