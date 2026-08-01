package com.pennywise.controller;

import com.pennywise.dto.auth.AuthResponse;
import com.pennywise.dto.auth.LoginRequest;
import com.pennywise.dto.auth.OtpRequest;
import com.pennywise.dto.auth.OtpSendResponse;
import com.pennywise.dto.auth.OtpVerifyRequest;
import com.pennywise.dto.auth.RefreshRequest;
import com.pennywise.dto.auth.RegisterRequest;
import com.pennywise.service.AuthService;
import com.pennywise.service.OtpService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final AuthService authService;
    private final OtpService otpService;

    public AuthController(AuthService authService, OtpService otpService) {
        this.authService = authService;
        this.otpService = otpService;
    }

    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest request) {
        return ResponseEntity.ok(authService.refresh(request));
    }

    @PostMapping("/send-otp")
    public ResponseEntity<OtpSendResponse> sendOtp(@Valid @RequestBody OtpRequest request) {
        return ResponseEntity.ok(otpService.sendOtp(request.getPhone()));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<AuthResponse> verifyOtp(@Valid @RequestBody OtpVerifyRequest request) {
        return ResponseEntity.ok(otpService.verifyOtp(request.getPhone(), request.getOtp()));
    }
}
