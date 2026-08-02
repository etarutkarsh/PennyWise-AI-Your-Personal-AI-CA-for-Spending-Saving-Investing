package com.pennywise.repository;

import com.pennywise.entity.FinancialDigitalTwin;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface FinancialDigitalTwinRepository extends JpaRepository<FinancialDigitalTwin, UUID> {

    Optional<FinancialDigitalTwin> findByUserId(UUID userId);
}
