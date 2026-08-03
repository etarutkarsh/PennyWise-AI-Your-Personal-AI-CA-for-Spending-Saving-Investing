import '../../../domain/ingestion/merchant_learning_entry.dart';
import '../../../domain/ingestion/merchant_profile.dart';
import '../../../domain/ingestion/parser_versions.dart';
import '../../../infrastructure/engines/learning_aware_merchant_resolver.dart';

/// Resolves a merchant learning queue entry.
///
/// Steps:
///   1. Validates the canonical merchant id exists in the resolver's known profiles.
///   2. Marks the queue entry as resolved (with parserVersion).
///   3. Adds the raw merchant string as a new alias in the runtime resolver.
///   4. Returns a ResolveResult with the scope for event replay.
///
/// After calling this use case, the caller should trigger EventReplayEngine
/// with the replay scope to retroactively improve historical transactions.
class ResolveMerchantEntryUseCase {
  const ResolveMerchantEntryUseCase({
    required MerchantLearningQueue queue,
    required LearningAwareMerchantResolver resolver,
  })  : _queue = queue,
        _resolver = resolver;

  final MerchantLearningQueue _queue;
  final LearningAwareMerchantResolver _resolver;

  ResolveResult call(ResolveMerchantParams params) {
    // 1. Look up the profile in the resolver's known profiles
    final profile = _resolver.allProfiles
        .where((p) => p.id == params.canonicalMerchantId)
        .firstOrNull;

    if (profile == null) {
      return ResolveResult.notFound(params.canonicalMerchantId);
    }

    // 2. Create an enriched profile including the new raw alias
    final enrichedProfile = MerchantProfile(
      id: profile.id,
      canonicalName: profile.canonicalName,
      category: profile.category,
      aliases: [...profile.aliases, params.rawMerchant],
      upiHandles: profile.upiHandles,
      isSubscription: profile.isSubscription,
      isInvestment: profile.isInvestment,
      isDebt: profile.isDebt,
      isInsurance: profile.isInsurance,
      confidence: profile.confidence,
    );

    // 3. Add to runtime resolver — takes effect for all subsequent SMS
    _resolver.addRuntimeMerchant(enrichedProfile);

    // 4. Mark queue entry as resolved
    _queue.resolve(
      params.rawMerchant,
      canonicalId: params.canonicalMerchantId,
      parserVersion: params.resolvedByVersion ?? kSmsParserVersion,
    );

    return ResolveResult.success(
      canonicalId: params.canonicalMerchantId,
      profile: enrichedProfile,
      rawMerchant: params.rawMerchant,
    );
  }
}

class ResolveMerchantParams {
  const ResolveMerchantParams({
    required this.rawMerchant,
    required this.canonicalMerchantId,
    this.resolvedByVersion,
  });

  final String rawMerchant;
  final String canonicalMerchantId;

  /// Parser version at resolution time — scopes event replay.
  final String? resolvedByVersion;
}

class ResolveResult {
  const ResolveResult._({
    required this.success,
    this.canonicalId,
    this.profile,
    this.rawMerchant,
    this.errorMessage,
  });

  final bool success;
  final String? canonicalId;
  final MerchantProfile? profile;
  final String? rawMerchant;
  final String? errorMessage;

  factory ResolveResult.success({
    required String canonicalId,
    required MerchantProfile profile,
    required String rawMerchant,
  }) =>
      ResolveResult._(
        success: true,
        canonicalId: canonicalId,
        profile: profile,
        rawMerchant: rawMerchant,
      );

  factory ResolveResult.notFound(String canonicalId) => ResolveResult._(
        success: false,
        errorMessage: 'Canonical merchant "$canonicalId" not found in resolver',
      );

  /// Replay scope: all events where rawMerchant matches this string.
  /// Caller passes this to EventReplayEngine.replay().
  String? get replayMerchantFilter => success ? rawMerchant : null;
}
