package com.pennywise.repository;

import com.pennywise.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    List<Transaction> findByUserIdOrderByTransactionDateDesc(UUID userId);

    List<Transaction> findByUserIdAndTransactionDateBetween(UUID userId, Instant from, Instant to);

    @Query("select coalesce(sum(t.amount), 0) from Transaction t " +
           "where t.userId = :userId and t.category.id = :categoryId " +
           "and t.transactionDate between :from and :to and t.direction = 'DEBIT'")
    java.math.BigDecimal sumByCategoryAndPeriod(@Param("userId") UUID userId,
                                                 @Param("categoryId") UUID categoryId,
                                                 @Param("from") Instant from,
                                                 @Param("to") Instant to);
}
