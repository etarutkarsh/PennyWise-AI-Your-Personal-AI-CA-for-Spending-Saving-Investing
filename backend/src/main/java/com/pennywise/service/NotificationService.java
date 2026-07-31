package com.pennywise.service;

import com.pennywise.dto.NotificationDto;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Notification;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.NotificationRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final BudgetRepository budgetRepository;
    private final GoalRepository goalRepository;
    private final TransactionRepository transactionRepository;
    private final CurrentUserProvider currentUserProvider;

    public NotificationService(NotificationRepository notificationRepository,
                                BudgetRepository budgetRepository,
                                GoalRepository goalRepository,
                                TransactionRepository transactionRepository,
                                CurrentUserProvider currentUserProvider) {
        this.notificationRepository = notificationRepository;
        this.budgetRepository = budgetRepository;
        this.goalRepository = goalRepository;
        this.transactionRepository = transactionRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public List<NotificationDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        generateIfStale(user);
        return notificationRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public NotificationDto markRead(UUID notificationId) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));
        n.setRead(true);
        return toDto(notificationRepository.save(n));
    }

    @Transactional
    public void markAllRead() {
        User user = currentUserProvider.get();
        notificationRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .forEach(n -> n.setRead(true));
    }

    // Generate smart notifications from budget/goal state. Runs at most once per day.
    private void generateIfStale(User user) {
        Instant oneDayAgo = Instant.now().minus(1, ChronoUnit.DAYS);
        List<Notification> existing = notificationRepository.findByUserIdOrderByCreatedAtDesc(user.getId());
        boolean hasRecent = existing.stream().anyMatch(n -> n.getCreatedAt().isAfter(oneDayAgo));
        if (hasRecent) return;

        Instant monthStart = Instant.now().minus(30, ChronoUnit.DAYS);

        // Budget overspend alerts
        List<Budget> budgets = budgetRepository.findByUserIdAndPeriod(user.getId(), currentMonthPeriod());
        List<Transaction> monthlyDebits = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), monthStart, Instant.now())
                .stream().filter(t -> t.getDirection() == Transaction.TransactionDirection.DEBIT).toList();

        for (Budget budget : budgets) {
            if (budget.getCategory() == null || budget.getMonthlyLimit() == null) continue;
            UUID catId = budget.getCategory().getId();
            BigDecimal spent = monthlyDebits.stream()
                    .filter(t -> t.getCategory() != null && catId.equals(t.getCategory().getId()))
                    .map(Transaction::getAmount)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);
            BigDecimal limit = budget.getMonthlyLimit();
            double pct = limit.compareTo(BigDecimal.ZERO) > 0
                    ? spent.doubleValue() / limit.doubleValue() : 0;
            if (pct >= 1.0) {
                save(user.getId(), "budget_exceeded",
                        "Budget exceeded",
                        String.format("You've spent ₹%.0f of your ₹%.0f budget this month.",
                                spent.doubleValue(), limit.doubleValue()));
            } else if (pct >= 0.85) {
                save(user.getId(), "overspend",
                        "Approaching budget limit",
                        String.format("You've used %.0f%% of your budget. ₹%.0f remaining.",
                                pct * 100, limit.subtract(spent).doubleValue()));
            }
        }

        // Goal behind-schedule alerts
        for (Goal goal : goalRepository.findByUserIdOrderByDeadlineAsc(user.getId())) {
            if (goal.isAchieved()) continue;
            BigDecimal needed = goal.getRecommendedMonthlyContribution();
            if (needed == null || needed.compareTo(BigDecimal.ZERO) <= 0) continue;
            save(user.getId(), "goal_behind",
                    "Goal reminder: " + goal.getName(),
                    String.format("Add ₹%.0f this month to stay on track for your %s goal.",
                            needed.doubleValue(), goal.getName()));
        }
    }

    private void save(UUID userId, String type, String title, String body) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setType(type);
        n.setTitle(title);
        n.setBody(body);
        notificationRepository.save(n);
    }

    private String currentMonthPeriod() {
        java.time.YearMonth ym = java.time.YearMonth.now();
        return ym.getYear() + "-" + String.format("%02d", ym.getMonthValue());
    }

    private NotificationDto toDto(Notification n) {
        return NotificationDto.builder()
                .id(n.getId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .read(n.isRead())
                .createdAt(n.getCreatedAt())
                .build();
    }
}
