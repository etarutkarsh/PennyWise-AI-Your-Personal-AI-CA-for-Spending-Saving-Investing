package com.pennywise.domain.decision;

import java.util.List;

public record TrustData(
        String engineVersion,
        String generatedAt,
        List<String> basedOn,
        List<String> missingData,
        String confidenceLevel,
        String commissionPolicy,
        String fiduciaryStatement
) {}
