// Defines the abstract KnowledgeGraphEngine interface — not yet built.

import '../shared/result.dart';
import '../value_objects/ids.dart';
import '../finance/financial_state.dart';

/// Abstract contract for the Knowledge Graph Engine (not built).
/// Provides user context from the financial knowledge graph and classifies financial state.
abstract class KnowledgeGraphEngine {
  String get engineVersion;
  bool get isEnabled;

  Future<Result<Map<String, dynamic>>> getUserContext({required UserId userId});

  Future<Result<FinancialState>> classifyFinancialState({required UserId userId});
}
