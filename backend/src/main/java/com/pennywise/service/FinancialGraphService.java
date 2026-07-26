package com.pennywise.service;

import com.pennywise.dto.FinancialGraphResponse;
import com.pennywise.dto.FinancialGraphResponse.Edge;
import com.pennywise.dto.FinancialGraphResponse.Node;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Goal;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.GoalRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class FinancialGraphService {

    private final TransactionRepository transactionRepository;
    private final BudgetRepository budgetRepository;
    private final GoalRepository goalRepository;
    private final CurrentUserProvider currentUserProvider;

    public FinancialGraphService(TransactionRepository transactionRepository,
                                  BudgetRepository budgetRepository,
                                  GoalRepository goalRepository,
                                  CurrentUserProvider currentUserProvider) {
        this.transactionRepository = transactionRepository;
        this.budgetRepository = budgetRepository;
        this.goalRepository = goalRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public FinancialGraphResponse build() {
        User user = currentUserProvider.get();

        YearMonth now = YearMonth.now();
        Instant from = now.atDay(1).atStartOfDay().toInstant(ZoneOffset.UTC);
        Instant to   = now.atEndOfMonth().atTime(23, 59, 59).toInstant(ZoneOffset.UTC);

        List<Transaction> txs = transactionRepository
                .findByUserIdAndTransactionDateBetween(user.getId(), from, to);
        List<Budget> budgets = budgetRepository.findByUserIdAndPeriod(
                user.getId(), now.toString());
        List<Goal> goals = goalRepository.findByUserIdOrderByDeadlineAsc(user.getId());

        List<Node> nodes = new ArrayList<>();
        List<Edge> edges = new ArrayList<>();

        // ── User node ────────────────────────────────────────────────────────
        String userId = "user:" + user.getId();
        nodes.add(Node.builder()
                .id(userId)
                .type("user")
                .props(Map.of(
                        "income", user.getMonthlyIncome() != null ? user.getMonthlyIncome() : 0,
                        "riskAppetite", user.getRiskAppetite() != null ? user.getRiskAppetite() : "medium",
                        "userType", user.getUserType() != null ? user.getUserType() : "professional"
                ))
                .build());

        // ── Category nodes + spending edges ──────────────────────────────────
        Map<String, BigDecimal> spendByCategory = txs.stream()
                .filter(t -> "DEBIT".equals(t.getDirection().name()) && t.getCategory() != null)
                .collect(Collectors.groupingBy(
                        t -> t.getCategory().getName(),
                        Collectors.reducing(BigDecimal.ZERO, Transaction::getAmount, BigDecimal::add)
                ));

        for (Map.Entry<String, BigDecimal> entry : spendByCategory.entrySet()) {
            String catId = "category:" + entry.getKey();
            nodes.add(Node.builder()
                    .id(catId)
                    .type("category")
                    .props(Map.of("name", entry.getKey(), "spent", entry.getValue()))
                    .build());
            edges.add(Edge.builder()
                    .from(userId).to(catId)
                    .relation("spent_in")
                    .props(Map.of("amount", entry.getValue(), "month", now.toString()))
                    .build());
        }

        // ── Budget nodes ──────────────────────────────────────────────────────
        for (Budget b : budgets) {
            String budgetId = "budget:" + b.getId();
            boolean over = b.getSpentSoFar().compareTo(b.getMonthlyLimit()) > 0;
            nodes.add(Node.builder()
                    .id(budgetId)
                    .type("budget")
                    .props(Map.of(
                            "limit", b.getMonthlyLimit(),
                            "spent", b.getSpentSoFar(),
                            "remaining", b.getMonthlyLimit().subtract(b.getSpentSoFar()),
                            "overBudget", over
                    ))
                    .build());
            edges.add(Edge.builder()
                    .from(userId).to(budgetId)
                    .relation(over ? "over_budget" : "on_budget")
                    .props(Map.of("pctUsed",
                            b.getMonthlyLimit().compareTo(BigDecimal.ZERO) > 0
                                    ? b.getSpentSoFar()
                                      .divide(b.getMonthlyLimit(), 2, RoundingMode.HALF_UP)
                                      .multiply(BigDecimal.valueOf(100))
                                    : BigDecimal.ZERO))
                    .build());
        }

        // ── Goal nodes ────────────────────────────────────────────────────────
        for (Goal g : goals) {
            String goalId = "goal:" + g.getId();
            double pct = g.getTargetAmount().compareTo(BigDecimal.ZERO) > 0
                    ? g.getCurrentSaved()
                       .divide(g.getTargetAmount(), 4, RoundingMode.HALF_UP)
                       .doubleValue() * 100
                    : 0;
            nodes.add(Node.builder()
                    .id(goalId)
                    .type("goal")
                    .props(Map.of(
                            "name", g.getName(),
                            "target", g.getTargetAmount(),
                            "saved", g.getCurrentSaved(),
                            "progressPct", Math.round(pct),
                            "deadline", g.getDeadline() != null ? g.getDeadline().toString() : "none"
                    ))
                    .build());
            edges.add(Edge.builder()
                    .from(userId).to(goalId)
                    .relation("saved_toward")
                    .props(Map.of("progressPct", Math.round(pct)))
                    .build());
        }

        // ── Summary ───────────────────────────────────────────────────────────
        BigDecimal totalDebit = txs.stream()
                .filter(t -> "DEBIT".equals(t.getDirection().name()))
                .map(Transaction::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalCredit = txs.stream()
                .filter(t -> "CREDIT".equals(t.getDirection().name()))
                .map(Transaction::getAmount).reduce(BigDecimal.ZERO, BigDecimal::add);
        long overBudgetCount = budgets.stream()
                .filter(b -> b.getSpentSoFar().compareTo(b.getMonthlyLimit()) > 0).count();

        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("month", now.toString());
        summary.put("totalSpent", totalDebit);
        summary.put("totalIncome", totalCredit);
        summary.put("budgetsOverLimit", overBudgetCount);
        summary.put("budgetsTotal", budgets.size());
        summary.put("goalsTotal", goals.size());
        summary.put("topSpendCategory", spendByCategory.entrySet().stream()
                .max(Map.Entry.comparingByValue())
                .map(e -> e.getKey() + " (₹" + e.getValue() + ")")
                .orElse("none"));

        return FinancialGraphResponse.builder()
                .nodes(nodes)
                .edges(edges)
                .summary(summary)
                .build();
    }

    /** Compact text representation for use in AI system prompts. */
    public String toPromptContext(FinancialGraphResponse graph) {
        StringBuilder sb = new StringBuilder();
        sb.append("Financial Graph (").append(graph.getSummary().get("month")).append("):\n");
        sb.append("  Spent: ₹").append(graph.getSummary().get("totalSpent"));
        sb.append(" | Over-budget categories: ").append(graph.getSummary().get("budgetsOverLimit"));
        sb.append("/").append(graph.getSummary().get("budgetsTotal")).append("\n");
        sb.append("  Top spend: ").append(graph.getSummary().get("topSpendCategory")).append("\n");

        long overBudget = graph.getEdges().stream()
                .filter(e -> "over_budget".equals(e.getRelation())).count();
        if (overBudget > 0) {
            sb.append("  ⚠ ").append(overBudget).append(" budget(s) exceeded this month\n");
        }

        graph.getNodes().stream()
                .filter(n -> "goal".equals(n.getType()))
                .forEach(n -> sb.append("  Goal [").append(n.getProps().get("name"))
                        .append("]: ").append(n.getProps().get("progressPct"))
                        .append("% of ₹").append(n.getProps().get("target"))
                        .append(" saved\n"));

        return sb.toString();
    }
}
