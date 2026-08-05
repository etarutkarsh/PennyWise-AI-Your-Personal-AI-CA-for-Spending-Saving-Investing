import '../../domain/reasoning/policy/policy_state_record.dart';

/// In-memory implementation of [PolicyStateRepository].
///
/// Sprint 11A: stores the current policy state per user in a Map for the
/// lifetime of the app session. No persistence — state is lost on app restart.
/// Sprint 12: replace with SQLite-backed implementation.
class InMemoryPolicyStateRepository implements PolicyStateRepository {
  InMemoryPolicyStateRepository();

  static const String _kVersion = 'policy-state-mem-v1';

  final Map<String, PolicyStateRecord> _store = {};

  @override
  String get engineVersion => _kVersion;

  @override
  Future<PolicyStateRecord?> getForUser(String userId) async =>
      _store[userId];

  @override
  Future<void> save(PolicyStateRecord record) async {
    _store[record.userId] = record;
  }
}
