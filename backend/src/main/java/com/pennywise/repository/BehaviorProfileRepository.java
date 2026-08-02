package com.pennywise.repository;

import com.pennywise.entity.BehaviorProfile;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface BehaviorProfileRepository extends JpaRepository<BehaviorProfile, UUID> {
    Optional<BehaviorProfile> findByUserId(UUID userId);
}
