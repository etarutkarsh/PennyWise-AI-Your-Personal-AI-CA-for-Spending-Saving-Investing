import '../../domain/engines/merchant_resolver.dart';
import '../../domain/ingestion/merchant_learning_entry.dart';
import '../../domain/ingestion/merchant_profile.dart';
import '../../domain/ingestion/parser_versions.dart';

/// Merchant resolver that learns from unknown encounters.
///
/// Wraps any base MerchantResolver (typically HardcodedMerchantResolver) and:
///   1. Auto-records every unresolved merchant to the MerchantLearningQueue.
///   2. Accepts runtime merchant additions resolved from the queue.
///   3. Checks runtime additions before falling back to the base resolver.
///
/// This closes the learning loop:
///   SMS → unknown merchant → queued → human review → resolved →
///   addRuntimeMerchant() → subsequent SMS resolved instantly →
///   event replay improves historical records.
class LearningAwareMerchantResolver implements MerchantResolver {
  LearningAwareMerchantResolver({
    required MerchantResolver baseResolver,
    required MerchantLearningQueue learningQueue,
    String parserVersion = kSmsParserVersion,
  })  : _base = baseResolver,
        _queue = learningQueue,
        _parserVersion = parserVersion;

  final MerchantResolver _base;
  final MerchantLearningQueue _queue;
  final String _parserVersion;

  static const _kVersion = 'merchant-resolver-learning-v1';

  // Runtime additions: normalizedKey → MerchantProfile
  // These come from resolved MerchantLearningEntries.
  final Map<String, MerchantProfile> _runtimeMerchants = {};

  @override
  String get engineVersion => _kVersion;

  @override
  MerchantProfile resolve(String rawMerchant) {
    if (rawMerchant.isEmpty) return UnknownMerchantProfile(rawMerchant);

    // 1. Check runtime additions first (highest priority — human-verified)
    final key = _normalizeKey(rawMerchant);
    if (_runtimeMerchants.containsKey(key)) {
      return _runtimeMerchants[key]!;
    }

    // 2. Partial match against runtime additions
    for (final entry in _runtimeMerchants.entries) {
      if (entry.key.isNotEmpty &&
          (key.startsWith(entry.key) || entry.key.startsWith(key))) {
        return entry.value;
      }
    }

    // 3. Fall back to base resolver (HardcodedMerchantResolver)
    final result = _base.resolve(rawMerchant);

    // 4. If unresolved, queue for human review
    if (!result.isKnown) {
      _queue.record(rawMerchant, parserVersion: _parserVersion);
    }

    return result;
  }

  @override
  List<MerchantProfile> resolveAll(List<String> rawMerchants) =>
      rawMerchants.map(resolve).toList();

  @override
  List<MerchantProfile> get allProfiles => [
        ..._base.allProfiles,
        ..._runtimeMerchants.values.toSet().toList(),
      ];

  /// Add a merchant profile at runtime — called after a queue entry is resolved.
  ///
  /// All aliases in the profile are indexed in the runtime map.
  /// This takes effect for all subsequent resolve() calls immediately.
  void addRuntimeMerchant(MerchantProfile profile) {
    // Index by canonical id
    _runtimeMerchants[profile.id] = profile;
    // Index by each alias
    for (final alias in profile.aliases) {
      final key = _normalizeKey(alias);
      if (key.isNotEmpty) {
        _runtimeMerchants[key] = profile;
      }
    }
    // Index by UPI handles
    for (final handle in profile.upiHandles) {
      final key = _normalizeKey(handle);
      if (key.isNotEmpty) {
        _runtimeMerchants[key] = profile;
      }
    }
  }

  /// Remove a runtime merchant by canonical id.
  void removeRuntimeMerchant(String merchantId) {
    _runtimeMerchants.removeWhere((_, profile) => profile.id == merchantId);
  }

  /// Number of merchants added at runtime (resolved from learning queue).
  int get runtimeMerchantCount =>
      _runtimeMerchants.values.map((p) => p.id).toSet().length;

  static String _normalizeKey(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s@.]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
