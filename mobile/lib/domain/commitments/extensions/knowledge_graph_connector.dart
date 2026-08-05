/// Stub — blocked on Knowledge Graph platform (Phase 6).
abstract interface class CommitmentKnowledgeGraphConnector {
  void emitCommitmentNode(
      String merchantKey, double monthlyAmount, String category);
  void emitCashFlowEdge(String fromNode, String toNode, double weight);
  void emitGoalImpactEdge(String merchantKey, String goalId, double impactScore);
}
