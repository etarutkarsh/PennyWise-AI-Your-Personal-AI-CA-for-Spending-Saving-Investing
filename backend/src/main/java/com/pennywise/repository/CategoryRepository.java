package com.pennywise.repository;

import com.pennywise.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    List<Category> findBySystemDefaultTrueOrUserId(UUID userId);
}
