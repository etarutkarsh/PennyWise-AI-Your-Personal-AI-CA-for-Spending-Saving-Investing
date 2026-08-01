package com.pennywise.service;

import com.pennywise.config.security.JwtService;
import com.pennywise.dto.auth.AuthResponse;
import com.pennywise.dto.auth.OtpSendResponse;
import com.pennywise.entity.User;
import com.pennywise.repository.UserRepository;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.transaction.annotation.Transactional;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.time.Duration;
import java.util.Optional;

@Service
public class OtpService {

    private static final Logger log = LoggerFactory.getLogger(OtpService.class);
    private static final Duration OTP_TTL      = Duration.ofMinutes(5);
    private static final int     MAX_ATTEMPTS  = 5;
    private static final int     MAX_SENDS     = 3;
    private static final Duration SEND_WINDOW  = Duration.ofMinutes(10);
    private static final String  KEY_OTP       = "otp:code:";
    private static final String  KEY_ATTEMPTS  = "otp:attempts:";
    private static final String  KEY_SENDS     = "otp:sends:";
    private static final String  F2S_URL      = "https://www.fast2sms.com/dev/bulkV2";

    @Value("${fast2sms.api-key:}") private String fast2smsKey;

    private final StringRedisTemplate redis;
    private final UserRepository      userRepository;
    private final JwtService          jwtService;
    private final SecureRandom        random     = new SecureRandom();
    private final HttpClient          httpClient = HttpClient.newHttpClient();
    private boolean smsEnabled = false;

    public OtpService(StringRedisTemplate redis,
                      UserRepository userRepository,
                      JwtService jwtService) {
        this.redis          = redis;
        this.userRepository = userRepository;
        this.jwtService     = jwtService;
    }

    @PostConstruct
    void init() {
        if (fast2smsKey != null && !fast2smsKey.isBlank()) {
            smsEnabled = true;
            log.info("Fast2SMS enabled — OTPs will be delivered via SMS.");
        } else {
            log.warn("FAST2SMS_API_KEY not set — running in dev mode (OTP returned in API response).");
        }
    }

    public OtpSendResponse sendOtp(String phone) {
        String normalised = normalise(phone);

        // Rate-limit sends: max MAX_SENDS per SEND_WINDOW per number
        Long sends = redis.opsForValue().increment(KEY_SENDS + normalised);
        if (sends != null && sends == 1) {
            redis.expire(KEY_SENDS + normalised, SEND_WINDOW);
        }
        if (sends != null && sends > MAX_SENDS) {
            throw new BadCredentialsException("Too many OTP requests. Please wait 10 minutes before trying again.");
        }

        String otp = String.format("%06d", random.nextInt(1_000_000));
        redis.opsForValue().set(KEY_OTP + normalised, otp, OTP_TTL);
        // Do NOT reset attempt counter on re-send — would allow brute-force bypass

        if (smsEnabled) {
            try {
                sendSms(normalised, otp);
            } catch (Exception e) {
                log.warn("[DEV FALLBACK] SMS failed ({}). OTP for {} logged above.", e.getMessage(), mask(normalised));
                log.info("[DEV] OTP for {} → {}", normalised, otp);
            }
        } else {
            log.info("[DEV] OTP for {} → {}", normalised, otp);
        }
        // Never return OTP in response — check server logs in dev mode
        return new OtpSendResponse("OTP sent to " + mask(normalised), null);
    }

    private void sendSms(String normalised, String otp) {
        // Fast2SMS Quick route — no DLT/website verification required.
        // normalised is "91XXXXXXXXXX", API expects just the 10-digit part.
        String tenDigit = normalised.startsWith("91") && normalised.length() == 12
                ? normalised.substring(2)
                : normalised;

        String message = otp + " is your PennyWise OTP. Valid for 5 minutes. Do not share.";

        // POST keeps API key and OTP out of URL query strings (proxy logs)
        String body = "route=q"
                + "&message=" + URLEncoder.encode(message, StandardCharsets.UTF_8)
                + "&numbers=" + tenDigit
                + "&flash=0";

        HttpRequest req = HttpRequest.newBuilder()
                .uri(URI.create(F2S_URL))
                .header("authorization", fast2smsKey)
                .header("Accept", "application/json")
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        try {
            HttpResponse<String> res = httpClient.send(req, HttpResponse.BodyHandlers.ofString());
            boolean httpError = res.statusCode() != 200;
            boolean apiError  = res.body().contains("\"return\":false")
                             || res.body().contains("status_code") && !res.body().contains("\"return\":true");
            if (httpError || apiError) {
                log.error("Fast2SMS error (status={}): {}", res.statusCode(), res.body());
                throw new RuntimeException("Failed to send OTP SMS. Please try again.");
            }
            log.info("Fast2SMS OTP sent to {}", mask(normalised));
        } catch (RuntimeException e) {
            throw e;
        } catch (Exception e) {
            log.error("Fast2SMS request failed", e);
            throw new RuntimeException("Failed to send OTP SMS. Please try again.");
        }
    }

    @Transactional
    public AuthResponse verifyOtp(String phone, String otp) {
        String normalised = normalise(phone);
        String key    = KEY_OTP + normalised;
        String attKey = KEY_ATTEMPTS + normalised;

        String stored = redis.opsForValue().get(key);
        if (stored == null) {
            throw new BadCredentialsException("OTP expired or not requested. Please request a new one.");
        }

        Long attempts = redis.opsForValue().increment(attKey);
        if (attempts != null && attempts > MAX_ATTEMPTS) {
            redis.delete(key);
            throw new BadCredentialsException("Too many incorrect attempts. Request a new OTP.");
        }

        if (!stored.equals(otp)) {
            long remaining = MAX_ATTEMPTS - attempts;
            throw new BadCredentialsException("Incorrect OTP. " + remaining + " attempt(s) remaining.");
        }

        redis.delete(key);
        redis.delete(attKey);

        Optional<User> existing = userRepository.findByPhoneNumber(normalised);
        User user = existing.orElseGet(() -> {
            try {
                return createPhoneUser(normalised);
            } catch (DataIntegrityViolationException e) {
                // Concurrent request already created the user — re-fetch
                return userRepository.findByPhoneNumber(normalised)
                        .orElseThrow(() -> new IllegalStateException("User lookup failed after concurrent insert", e));
            }
        });

        return new AuthResponse(
                jwtService.generateAccessToken(user.getId(), user.getEmail()),
                jwtService.generateRefreshToken(user.getId(), user.getEmail()),
                user.getId()
        );
    }

    private User createPhoneUser(String phone) {
        User u = new User();
        u.setPhoneNumber(phone);
        u.setEmail(phone + "@phone.pennywise.ai");
        u.setPasswordHash("");
        return userRepository.save(u);
    }

    /** Normalise to 12-digit (91 + 10-digit). Accepts +91XXXXXXXXXX or 10-digit. */
    private String normalise(String phone) {
        String digits = phone.replaceAll("[^\\d]", "");
        if (digits.length() == 10) digits = "91" + digits;
        return digits;
    }

    private String mask(String phone) {
        if (phone.length() <= 4) return "****";
        return phone.substring(0, phone.length() - 4) + "****";
    }
}
