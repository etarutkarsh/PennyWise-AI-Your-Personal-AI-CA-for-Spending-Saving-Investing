package com.pennywise.dto.decision;

public record PartnerOption(
        String partner,
        double rate,
        double minAmount,
        String feature,
        String ctaLabel,
        String link
) {}
