package com.pennywise.repository;

import com.pennywise.entity.Liability;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LiabilityRepository extends JpaRepository<Liability, UUID> {
    List<Liability> findByUserIdOrderByCreatedAtDesc(UUID userId);
}
