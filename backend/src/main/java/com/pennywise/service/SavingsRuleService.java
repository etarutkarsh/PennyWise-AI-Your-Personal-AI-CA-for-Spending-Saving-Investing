package com.pennywise.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.pennywise.dto.SavingsRuleCreateRequest;
import com.pennywise.dto.SavingsRuleDto;
import com.pennywise.entity.Category;
import com.pennywise.entity.SavingsRule;
import com.pennywise.entity.User;
import com.pennywise.exception.ResourceNotFoundException;
import com.pennywise.repository.CategoryRepository;
import com.pennywise.repository.SavingsRuleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class SavingsRuleService {

    private final SavingsRuleRepository savingsRuleRepository;
    private final CategoryRepository categoryRepository;
    private final CurrentUserProvider currentUserProvider;
    private final ObjectMapper objectMapper;

    public SavingsRuleService(SavingsRuleRepository savingsRuleRepository,
                              CategoryRepository categoryRepository,
                              CurrentUserProvider currentUserProvider,
                              ObjectMapper objectMapper) {
        this.savingsRuleRepository = savingsRuleRepository;
        this.categoryRepository = categoryRepository;
        this.currentUserProvider = currentUserProvider;
        this.objectMapper = objectMapper;
    }

    public List<SavingsRuleDto> getAll() {
        User user = currentUserProvider.get();
        return savingsRuleRepository.findByUserIdOrderByCreatedAtDesc(user.getId())
                .stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public SavingsRuleDto create(SavingsRuleCreateRequest request) {
        User user = currentUserProvider.get();

        SavingsRule rule = new SavingsRule();
        rule.setUserId(user.getId());
        rule.setTriggerType(request.getTriggerType());
        rule.setCategoryId(request.getCategoryId());
        rule.setActive(true);

        if (request.getConfig() != null) {
            try {
                rule.setConfigJson(objectMapper.writeValueAsString(request.getConfig()));
            } catch (JsonProcessingException e) {
                rule.setConfigJson("{}");
            }
        } else {
            rule.setConfigJson("{}");
        }

        return toDto(savingsRuleRepository.save(rule));
    }

    @Transactional
    public SavingsRuleDto toggleActive(UUID id) {
        SavingsRule rule = savingsRuleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Savings rule not found"));
        rule.setActive(!rule.isActive());
        return toDto(savingsRuleRepository.save(rule));
    }

    @Transactional
    public void delete(UUID id) {
        SavingsRule rule = savingsRuleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Savings rule not found"));
        savingsRuleRepository.delete(rule);
    }

    private SavingsRuleDto toDto(SavingsRule rule) {
        Map<String, Object> config = null;
        if (rule.getConfigJson() != null && !rule.getConfigJson().isBlank()) {
            try {
                config = objectMapper.readValue(rule.getConfigJson(),
                        new TypeReference<Map<String, Object>>() {});
            } catch (JsonProcessingException e) {
                config = Map.of();
            }
        }

        String categoryName = null;
        if (rule.getCategoryId() != null) {
            categoryName = categoryRepository.findById(rule.getCategoryId())
                    .map(Category::getName)
                    .orElse(null);
        }

        return SavingsRuleDto.builder()
                .id(rule.getId())
                .triggerType(rule.getTriggerType())
                .categoryId(rule.getCategoryId())
                .categoryName(categoryName)
                .config(config)
                .active(rule.isActive())
                .build();
    }
}
