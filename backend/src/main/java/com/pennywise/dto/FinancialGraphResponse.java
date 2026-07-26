package com.pennywise.dto;

import lombok.Builder;
import lombok.Data;

import java.util.List;
import java.util.Map;

/**
 * A lightweight graph of the user's financial world.
 * Nodes = entities (user, categories, goals, budgets).
 * Edges = relationships (spent_in, on_track, behind_on, saved_toward).
 * Consumed by ChatService to build a richer AI system prompt.
 */
@Data
@Builder
public class FinancialGraphResponse {
    private List<Node> nodes;
    private List<Edge> edges;
    private Map<String, Object> summary;

    @Data
    @Builder
    public static class Node {
        private String id;
        private String type;        // user | category | goal | budget
        private Map<String, Object> props;
    }

    @Data
    @Builder
    public static class Edge {
        private String from;
        private String to;
        private String relation;    // spent_in | has_goal | on_budget | over_budget | saved_toward
        private Map<String, Object> props;
    }
}
