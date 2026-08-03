package com.pennywise.domain.decision;

import java.util.List;

public record ExplanationData(
        String headline,
        String summary,
        List<String> because,
        List<String> evidence,
        List<String> alternatives,
        List<String> whyNot,
        List<String> tradeoffs,
        List<String> limitations,
        List<String> confidenceDrivers
) {}
