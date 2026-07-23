package com.pennywise.service;

import com.pennywise.dto.CategoryDto;
import com.pennywise.entity.Category;
import com.pennywise.entity.User;
import com.pennywise.repository.CategoryRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final CurrentUserProvider currentUserProvider;

    public CategoryService(CategoryRepository categoryRepository, CurrentUserProvider currentUserProvider) {
        this.categoryRepository = categoryRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public List<CategoryDto> listAvailable() {
        User user = currentUserProvider.get();
        return categoryRepository.findBySystemDefaultTrueOrUserId(user.getId())
                .stream()
                .map(this::toDto)
                .toList();
    }

    private CategoryDto toDto(Category c) {
        return CategoryDto.builder()
                .id(c.getId())
                .name(c.getName())
                .icon(c.getIcon())
                .type(c.getType())
                .systemDefault(c.isSystemDefault())
                .build();
    }
}
