package com.pennywise.domain.decision;

public record BehavioralContextData(
        String status,
        Double lossAversion,
        Double presentBias,
        Double riskTolerance,
        Double impulseVolatility
) {}
