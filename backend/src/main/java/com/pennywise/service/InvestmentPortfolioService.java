package com.pennywise.service;

import com.pennywise.dto.InvestmentPortfolioCreateRequest;
import com.pennywise.dto.InvestmentPortfolioDto;
import com.pennywise.entity.InvestmentPortfolio;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.InvestmentPortfolioRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class InvestmentPortfolioService {

    private final InvestmentPortfolioRepository repository;
    private final CurrentUserProvider currentUserProvider;

    public InvestmentPortfolioService(InvestmentPortfolioRepository repository,
                                       CurrentUserProvider currentUserProvider) {
        this.repository = repository;
        this.currentUserProvider = currentUserProvider;
    }

    @Transactional
    public InvestmentPortfolioDto create(InvestmentPortfolioCreateRequest request) {
        User user = currentUserProvider.get();
        InvestmentPortfolio inv = new InvestmentPortfolio();
        inv.setUserId(user.getId());
        inv.setInstrumentType(request.getInstrumentType());
        inv.setName(request.getName());
        inv.setInvestedAmount(request.getInvestedAmount());
        inv.setCurrentValue(request.getCurrentValue() != null
                ? request.getCurrentValue() : request.getInvestedAmount());
        inv.setUnits(request.getUnits());
        inv.setStartedOn(request.getStartedOn() != null ? request.getStartedOn() : LocalDate.now());
        return toDto(repository.save(inv));
    }

    public List<InvestmentPortfolioDto> listForCurrentUser() {
        User user = currentUserProvider.get();
        return repository.findByUserIdOrderByStartedOnDesc(user.getId())
                .stream().map(this::toDto).toList();
    }

    @Transactional
    public InvestmentPortfolioDto updateCurrentValue(UUID id, BigDecimal newCurrentValue) {
        InvestmentPortfolio inv = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Investment not found"));
        User user = currentUserProvider.get();
        if (!inv.getUserId().equals(user.getId())) {
            throw new ResourceNotFoundException("Investment not found");
        }
        inv.setCurrentValue(newCurrentValue);
        return toDto(repository.save(inv));
    }

    @Transactional
    public void delete(UUID id) {
        InvestmentPortfolio inv = repository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Investment not found"));
        User user = currentUserProvider.get();
        if (!inv.getUserId().equals(user.getId())) {
            throw new ResourceNotFoundException("Investment not found");
        }
        repository.delete(inv);
    }

    private InvestmentPortfolioDto toDto(InvestmentPortfolio inv) {
        BigDecimal current = inv.getCurrentValue() != null ? inv.getCurrentValue() : inv.getInvestedAmount();
        BigDecimal returnsAmount = current.subtract(inv.getInvestedAmount());
        double returnsPercent = inv.getInvestedAmount().compareTo(BigDecimal.ZERO) > 0
                ? returnsAmount.divide(inv.getInvestedAmount(), 4, RoundingMode.HALF_UP)
                    .multiply(BigDecimal.valueOf(100)).doubleValue()
                : 0.0;
        return InvestmentPortfolioDto.builder()
                .id(inv.getId())
                .instrumentType(inv.getInstrumentType())
                .name(inv.getName())
                .investedAmount(inv.getInvestedAmount())
                .currentValue(current)
                .units(inv.getUnits())
                .startedOn(inv.getStartedOn())
                .returnsAmount(returnsAmount)
                .returnsPercent(returnsPercent)
                .build();
    }
}
