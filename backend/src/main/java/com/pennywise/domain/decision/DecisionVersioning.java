package com.pennywise.domain.decision;

public record DecisionVersioning(
        String schemaVersion,
        String engineVersion,
        String decisionVersion,
        String behaviorVersion,
        String knowledgeVersion
) {}
