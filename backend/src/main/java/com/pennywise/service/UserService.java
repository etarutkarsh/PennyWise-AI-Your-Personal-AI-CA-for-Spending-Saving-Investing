package com.pennywise.service;

import com.pennywise.dto.UserDto;
import com.pennywise.dto.UserUpdateRequest;
import com.pennywise.entity.User;
import com.pennywise.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserService {

    private final UserRepository userRepository;
    private final CurrentUserProvider currentUserProvider;

    public UserService(UserRepository userRepository, CurrentUserProvider currentUserProvider) {
        this.userRepository = userRepository;
        this.currentUserProvider = currentUserProvider;
    }

    public UserDto getMe() {
        return toDto(currentUserProvider.get());
    }

    @Transactional
    public UserDto updateMe(UserUpdateRequest req) {
        User user = currentUserProvider.get();
        if (req.getFullName() != null) user.setFullName(req.getFullName());
        if (req.getPhoneNumber() != null) user.setPhoneNumber(req.getPhoneNumber());
        if (req.getMonthlyIncome() != null) user.setMonthlyIncome(req.getMonthlyIncome());
        if (req.getRiskAppetite() != null) user.setRiskAppetite(req.getRiskAppetite());
        return toDto(userRepository.save(user));
    }

    private UserDto toDto(User u) {
        return UserDto.builder()
                .id(u.getId())
                .email(u.getEmail())
                .fullName(u.getFullName())
                .phoneNumber(u.getPhoneNumber())
                .userType(u.getUserType())
                .monthlyIncome(u.getMonthlyIncome())
                .currency(u.getCurrency())
                .riskAppetite(u.getRiskAppetite())
                .onboardingComplete(u.isOnboardingComplete())
                .build();
    }
}
