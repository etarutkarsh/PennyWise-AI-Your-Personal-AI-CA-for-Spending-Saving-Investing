package com.pennywise.service;

import com.pennywise.dto.TransactionCreateRequest;
import com.pennywise.dto.TransactionDto;
import com.pennywise.entity.Category;
import com.pennywise.entity.Transaction;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.CategoryRepository;
import com.pennywise.repository.TransactionRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
public class TransactionService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentUserProvider currentUserProvider;

    public TransactionService(TransactionRepository transactionRepository,
                               CategoryRepository categoryRepository,
                               CurrentUserProvider currentUserProvider) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.currentUserProvider = currentUserProvider;
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

        if (request.getCategoryId() != null) {
            Category category = categoryRepository.findById(request.getCategoryId())
                    .orElseThrow(() -> new ResourceNotFoundException("Category not found"));
            tx.setCategory(category);
        }
        // TODO: if categoryId is null and source == SMS/EMAIL/OCR, invoke the
        // Expense AI auto-categorization model here (see ai/ package) and set
        // tx.setCategoryConfidence(...) accordingly.

        return toDto(transactionRepository.save(tx));
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
                .build();
    }
}
