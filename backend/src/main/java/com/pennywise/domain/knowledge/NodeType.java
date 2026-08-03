package com.pennywise.domain.knowledge;

/**
 * Discriminator for entity nodes in the financial knowledge graph.
 *
 * System nodes (INSTRUMENT, REGULATOR) have no user_id.
 * User nodes (all others) are scoped to a specific user.
 */
public enum NodeType {
    USER,
    ACCOUNT,
    GOAL,
    INCOME,
    COMMITMENT,
    MERCHANT,
    SUBSCRIPTION,
    LOAN,
    INSURANCE,
    ASSET,
    INSTRUMENT,
    REGULATOR,
    LIFE_EVENT
}
