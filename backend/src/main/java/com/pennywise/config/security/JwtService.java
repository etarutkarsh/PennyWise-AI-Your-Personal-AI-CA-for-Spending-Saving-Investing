package com.pennywise.config.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Service
public class JwtService {

    private final SecretKey key;
    private final long accessTokenExpiryMs;
    private final long refreshTokenExpiryMs;

    public JwtService(@Value("${security.jwt.secret}") String secret,
                       @Value("${security.jwt.access-token-expiry-ms}") long accessTokenExpiryMs,
                       @Value("${security.jwt.refresh-token-expiry-ms}") long refreshTokenExpiryMs) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTokenExpiryMs = accessTokenExpiryMs;
        this.refreshTokenExpiryMs = refreshTokenExpiryMs;
    }

    public String generateAccessToken(UUID userId, String email) {
        return buildToken(userId, email, accessTokenExpiryMs, "access");
    }

    public String generateRefreshToken(UUID userId, String email) {
        return buildToken(userId, email, refreshTokenExpiryMs, "refresh");
    }

    private String buildToken(UUID userId, String email, long expiryMs, String type) {
        Date now = new Date();
        return Jwts.builder()
                .subject(email)
                .claim("userId", userId.toString())
                .claim("type", type)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expiryMs))
                .signWith(key, SignatureAlgorithm.HS256)
                .compact();
    }

    public Claims parseClaims(String token) {
        return Jwts.parser()
                .verifyWith(key)
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public String extractEmail(String token) {
        return parseClaims(token).getSubject();
    }

    public UUID extractUserId(String token) {
        return UUID.fromString(parseClaims(token).get("userId", String.class));
    }

    public boolean isValid(String token) {
        try {
            Claims claims = parseClaims(token);
            return claims.getExpiration().after(new Date());
        } catch (Exception e) {
            return false;
        }
    }
}
