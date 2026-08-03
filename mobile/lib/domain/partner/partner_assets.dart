import 'package:flutter/foundation.dart';

import 'partner_icon_type.dart';

/// All visual assets for a partner brand.
///
/// All paths are nullable — null means use the fallback treatment.
/// When Sprint 2 bundles local files, set [logoAssetPath].
/// When Sprint 4 adds CDN, PartnerAssetService resolves a URL override
/// before this bundled path is consulted.
///
/// Theme-aware: widgets prefer [darkLogoAssetPath] in dark mode, falling
/// back to [logoAssetPath]. Sprint 2 only ships light-mode assets; dark
/// variants arrive when designs are ready.
@immutable
class PartnerAssets {
  const PartnerAssets({
    this.logoAssetPath,
    this.darkLogoAssetPath,
    this.lightLogoAssetPath,
    this.heroImageAssetPath,
    this.bannerAssetPath,
    required this.fallbackIcon,
    required this.fallbackLabel,
  });

  /// Bundled logo path, e.g. 'assets/images/partners/hdfc_logo.png'.
  /// Null until real assets are licensed and bundled (Sprint 2 step 2).
  final String? logoAssetPath;

  /// Dark-mode variant. Falls back to [logoAssetPath] if null.
  final String? darkLogoAssetPath;

  /// Explicit light-mode variant (for partners that supply separate files).
  final String? lightLogoAssetPath;

  /// Full-bleed hero used in detail sheets and onboarding.
  final String? heroImageAssetPath;

  /// Promotional banner for campaign slots.
  final String? bannerAssetPath;

  /// Always set — used when no image asset is available.
  final PartnerIconType fallbackIcon;

  /// Short brand name for the text-treatment fallback (1–6 chars).
  /// e.g. "HDFC", "jar", "fi", "AXIS"
  final String fallbackLabel;

  static const empty = PartnerAssets(
    fallbackIcon: PartnerIconType.generic,
    fallbackLabel: '—',
  );

  PartnerAssets copyWith({
    String? logoAssetPath,
    String? darkLogoAssetPath,
    String? lightLogoAssetPath,
    String? heroImageAssetPath,
    String? bannerAssetPath,
    PartnerIconType? fallbackIcon,
    String? fallbackLabel,
  }) =>
      PartnerAssets(
        logoAssetPath: logoAssetPath ?? this.logoAssetPath,
        darkLogoAssetPath: darkLogoAssetPath ?? this.darkLogoAssetPath,
        lightLogoAssetPath: lightLogoAssetPath ?? this.lightLogoAssetPath,
        heroImageAssetPath: heroImageAssetPath ?? this.heroImageAssetPath,
        bannerAssetPath: bannerAssetPath ?? this.bannerAssetPath,
        fallbackIcon: fallbackIcon ?? this.fallbackIcon,
        fallbackLabel: fallbackLabel ?? this.fallbackLabel,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartnerAssets &&
          other.logoAssetPath == logoAssetPath &&
          other.fallbackIcon == fallbackIcon &&
          other.fallbackLabel == fallbackLabel);

  @override
  int get hashCode => Object.hash(logoAssetPath, fallbackIcon, fallbackLabel);
}
