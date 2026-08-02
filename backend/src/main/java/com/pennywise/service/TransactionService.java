package com.pennywise.service;

import com.pennywise.dto.TransactionCreateRequest;
import com.pennywise.dto.TransactionDto;
import com.pennywise.dto.TransactionUpdateRequest;
import com.pennywise.engine.events.EventBus;
import com.pennywise.engine.events.domain.*;
import com.pennywise.entity.Budget;
import com.pennywise.entity.Category;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.BudgetRepository;
import com.pennywise.repository.CategoryRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.YearMonth;
import java.time.ZoneOffset;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final BudgetRepository budgetRepository;
    private final CurrentUserProvider currentUserProvider;
    private final EventBus eventBus;

    public TransactionService(TransactionRepository transactionRepository,
                               CategoryRepository categoryRepository,
                               BudgetRepository budgetRepository,
                               CurrentUserProvider currentUserProvider,
                               EventBus eventBus) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.budgetRepository = budgetRepository;
        this.currentUserProvider = currentUserProvider;
        this.eventBus = eventBus;
    }

    @Transactional
    public TransactionDto create(TransactionCreateRequest request) {
        User user = currentUserProvider.get();

        Transaction tx = new Transaction();
        tx.setUserId(user.getId());
        tx.setAmount(request.getAmount());
        tx.setMerchant(request.getMerchant());
        tx.setNote(request.getNote());
        tx.setTransactionDate(request.getTransactionDate());
        tx.setPaymentMethod(request.getPaymentMethod());
        tx.setDirection(Transaction.TransactionDirection.valueOf(request.getDirection().toUpperCase()));
        tx.setSource(request.getSource() != null ? request.getSource() : "MANUAL");
        tx.setReceiptUrl(request.getReceiptUrl());
        tx.setTaxCategory(request.getTaxCategory());
        tx.setBusinessExpense(request.isBusinessExpense());

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            tx.setCategory(category);
        }
        // TODO: if categoryId is null and source == SMS/EMAIL/OCR, invoke the
        // Expense AI auto-categorization model here (see ai/ package) and set
        // tx.setCategoryConfidence(...) accordingly.

        Transaction saved = transactionRepository.save(tx);
        publishTransactionEvents(user, saved);
        return toDto(saved);
    }

    private void publishTransactionEvents(User user, Transaction tx) {
        String direction = tx.getDirection().name();
        String categoryName = tx.getCategory() != null ? tx.getCategory().getName() : "Uncategorized";

        // Always emit transaction added
        eventBus.publish(new TransactionAddedEvent(
                user.getId(), tx.getAmount(), direction, categoryName, tx.getMerchant()));

        BigDecimal income = user.getMonthlyIncome();

        if ("CREDIT".equals(direction)) {
            // Salary detection: credit >= 50% of monthly income
            if (income != null && income.compareTo(BigDecimal.ZERO) > 0
                    && tx.getAmount().compareTo(income.multiply(new BigDecimal("0.5"))) >= 0) {
                eventBus.publish(new SalaryCreditedEvent(user.getId(), tx.getAmount()));
            }
        } else if ("DEBIT".equals(direction)) {
            // Large purchase detection: debit > 15% of monthly income
            if (income != null && income.compareTo(BigDecimal.ZERO) > 0
                    && tx.getAmount().compareTo(income.multiply(new BigDecimal("0.15"))) > 0) {
                double incomePercent = tx.getAmount()
                        .divide(income, 4, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100))
                        .doubleValue();
                eventBus.publish(new LargePurchaseDetectedEvent(
                        user.getId(), tx.getAmount(), tx.getMerchant(), income, incomePercent));
            }

            // Budget exceeded detection
            if (tx.getCategory() != null) {
                checkBudgetExceeded(user, tx);
            }
        }
    }

    private void checkBudgetExceeded(User user, Transaction tx) {
        String period = YearMonth.now().toString();
        budgetRepository.findByUserIdAndCategoryIdAndPeriod(
                user.getId(), tx.getCategory().getId(), period)
            .ifPresent(budget -> {
                YearMonth ym = YearMonth.now();
                Instant from = ym.atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();
                Instant to = ym.plusMonths(1).atDay(1).atStartOfDay(ZoneOffset.UTC).toInstant();
                BigDecimal totalSpent = transactionRepository.sumByCategoryAndPeriod(
                        user.getId(), tx.getCategory().getId(), from, to);
                if (totalSpent.compareTo(budget.getMonthlyLimit()) > 0) {
                    eventBus.publish(new BudgetExceededEvent(
                            user.getId(),
                            tx.getCategory().getName(),
                            budget.getMonthlyLimit(),
                            totalSpent));
                }
            });
    }

    public List<TransactionDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        return transactionRepository.findByUserIdOrderByTransactionDateDesc(user.getId())
                .stream().map(this::toDto).toList();
    }

    public List<TransactionDto> listForPeriod(Instant from, Instant to) {
        User user = currentUserProvider.get();
        return transactionRepository.findByUserIdAndTransactionDateBetween(user.getId(), from, to)
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public TransactionDto update(UUID id, TransactionUpdateRequest req) {
        Transaction tx = transactionRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Transaction not found"));
        User user = currentUserProvider.get();
        if (!tx.getUserId().equals(user.getId()))
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Access denied");

        if (req.getMerchant() != null) tx.setMerchant(req.getMerchant());
        if (req.getNote() != null) tx.setNote(req.getNote());
        if (req.getAmount() != null) tx.setAmount(req.getAmount());
        if (req.getRecurring() != null) tx.setRecurring(req.getRecurring());
        if (req.getPaymentMethod() != null) {
            tx.setPaymentMethod(req.getPaymentMethod());
        }
        if (req.getCategoryId() != null) {
            categoryRepository.findById(UUID.fromString(req.getCategoryId()))
                    .ifPresent(tx::setCategory);
        }
        return toDto(transactionRepository.save(tx));
    }

    public List<TransactionDto> listFiltered(String direction, String categoryName, String search) {
        User user = currentUserProvider.get();
        List<Transaction> all = transactionRepository.findByUserIdOrderByTransactionDateDesc(user.getId());
        return all.stream()
                .filter(t -> direction == null || t.getDirection().name().equalsIgnoreCase(direction))
                .filter(t -> categoryName == null || (t.getCategory() != null
                        && t.getCategory().getName().equalsIgnoreCase(categoryName)))
                .filter(t -> search == null || search.isBlank()
                        || (t.getMerchant() != null && t.getMerchant().toLowerCase().contains(search.toLowerCase()))
                        || (t.getNote() != null && t.getNote().toLowerCase().contains(search.toLowerCase())))
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    public void delete(UUID transactionId) {
        User user = currentUserProvider.get();
        Transaction tx = transactionRepository.findById(transactionId)
                .orElseThrow(() -> new ResourceNotFoundException("Transaction not found"));
        if (!tx.getUserId().equals(user.getId())) {
            throw new ResourceNotFoundException("Transaction not found");
        }
        transactionRepository.delete(tx);
    }

    private TransactionDto toDto(Transaction tx) {
        return TransactionDto.builder()
                .id(tx.getId())
                .amount(tx.getAmount())
                .merchant(tx.getMerchant())
                .note(tx.getNote())
                .categoryId(tx.getCategory() != null ? tx.getCategory().getId() : null)
                .categoryName(tx.getCategory() != null ? tx.getCategory().getName() : "Uncategorized")
                .transactionDate(tx.getTransactionDate())
                .paymentMethod(tx.getPaymentMethod())
                .direction(tx.getDirection().name())
                .source(tx.getSource())
                .recurring(tx.isRecurring())
                .receiptUrl(tx.getReceiptUrl())
                .taxCategory(tx.getTaxCategory())
                .verificationStatus(tx.getVerificationStatus().name())
                .businessExpense(tx.isBusinessExpense())
                .build();
    }
}
