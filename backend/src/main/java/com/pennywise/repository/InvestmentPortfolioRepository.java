package com.pennywise.repository;

import com.pennywise.entity.InvestmentPortfolio;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface InvestmentPortfolioRepository extends JpaRepository<InvestmentPortfolio, UUID> {
    List<InvestmentPortfolio> findByUserIdOrderByStartedOnDesc(UUID userId);
}
