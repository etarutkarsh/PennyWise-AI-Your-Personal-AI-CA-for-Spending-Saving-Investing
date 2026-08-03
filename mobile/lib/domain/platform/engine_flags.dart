// Defines EngineFlag enum representing every engine in the PennyWise platform and its build status.

/// Flags for every engine/capability in the PennyWise platform.
/// Use [PennyWiseFeatureFlags.isEnabled] to check if an engine is active.
enum EngineFlag {
  decisionEngineV1,         // built, in use
  decisionEngineV2,         // Tier 3 — multi-axis, not built
  behavioralEngine,         // Tier 5 — not built
  digitalTwin,              // stub — not calibrated
  partnerMatchingEngine,    // not built
  knowledgeGraph,           // not built
  healthEngineV2,           // Tier 2 — 10-dimension, not built
  accountAggregator,        // not built (Setu SDK)
  smsIntelligence,          // partial
  stepUpSipFormula,         // Tier 3 — not built
  monteCarlo,               // not built
  explainability,           // not built
  eventSourcing,            // not built
  subscriptionIntelligence, // not built
  academyAi,                // not built
}
