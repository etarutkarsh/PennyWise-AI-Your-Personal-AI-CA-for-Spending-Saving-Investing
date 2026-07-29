package com.pennywise.service;

import com.pennywise.config.security.JwtService;
import com.pennywise.dto.auth.AuthResponse;
import com.pennywise.dto.auth.LoginRequest;
import com.pennywise.dto.auth.RefreshRequest;
import com.pennywise.dto.auth.RegisterRequest;
import com.pennywise.entity.User;
import com.pennywise.exception.DuplicateResourceException;
import com.pennywise.repository.UserRepository;
import io.jsonwebtoken.Claims;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(UserRepository userRepository, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new DuplicateResourceException("An account with this email already exists");
        }

        User user = new User();
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setFullName(request.getFullName());
        user.setUserType(request.getUserType());

        user = userRepository.save(user);

        return new AuthResponse(
                jwtService.generateAccessToken(user.getId(), user.getEmail()),
                jwtService.generateRefreshToken(user.getId(), user.getEmail()),
                user.getId());
    }

    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadCredentialsException("Invalid email or password"));

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadCredentialsException("Invalid email or password");
        }

        return new AuthResponse(
                jwtService.generateAccessToken(user.getId(), user.getEmail()),
                jwtService.generateRefreshToken(user.getId(), user.getEmail()),
                user.getId());
    }

    public AuthResponse refresh(RefreshRequest request) {
        String token = request.getRefreshToken();
        if (!jwtService.isValid(token)) {
            throw new BadCredentialsException("Invalid or expired refresh token");
        }
        Claims claims = jwtService.parseClaims(token);
        if (!"refresh".equals(claims.get("type", String.class))) {
            throw new BadCredentialsException("Not a refresh token");
        }
        UUID userId = jwtService.extractUserId(token);
        String email = jwtService.extractEmail(token);
        return new AuthResponse(
                jwtService.generateAccessToken(userId, email),
                jwtService.generateRefreshToken(userId, email),
                userId);
    }
}
