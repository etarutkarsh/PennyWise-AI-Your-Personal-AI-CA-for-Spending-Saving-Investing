import '../ingestion/merchant_profile.dart';

/// The Financial Identity Resolution Engine.
/// Answers: "Are these the same merchant?"
///
/// NETFLIX / Netflix / NETFLIX-MUM / NETFLIX INDIA / Netflix.com → Netflix (id: 'netflix')
/// HDFC / HDFC BANK / HDFC LTD / HDFC HOME LOAN / HDFC SIP → different profiles
abstract class MerchantResolver {
  String get engineVersion;

  /// Resolve a raw merchant string to its canonical MerchantProfile.
  /// Returns UnknownMerchantProfile if no match found.
  MerchantProfile resolve(String rawMerchant);

  /// Resolve multiple strings at once (for batch normalization).
  List<MerchantProfile> resolveAll(List<String> rawMerchants) =>
      rawMerchants.map(resolve).toList();

  /// Return all known merchant profiles (for display in settings/UI).
  List<MerchantProfile> get allProfiles;
}
