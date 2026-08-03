import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/partner/partner_assets.dart';

/// Resolves the best available visual asset for a partner, theme-aware.
///
/// Resolution order (highest priority first):
///   1. CDN manifest override (Sprint 4 — not yet wired)
///   2. Bundled asset path from [PartnerAssets] fields
///   3. Text fallback via [PartnerAssets.fallbackLabel] + [PartnerAssets.fallbackIcon]
///
/// The service is intentionally synchronous for bundled assets — no
/// async loading in the render path. The Sprint 4 CDN manifest will be
/// pre-fetched at app startup and cached, so widgets still call sync methods.
class PartnerAssetService {
  PartnerAssetService._();
  static final PartnerAssetService instance = PartnerAssetService._();

  // Sprint 4: cached CDN manifest overrides keyed by partnerId.
  // final Map<String, Map<String, String?>> _cdnOverrides = {};

  /// Returns the most appropriate logo asset path for the given [assets]
  /// and display [brightness]. Returns null when no bundled image is available,
  /// meaning the widget should render the text fallback treatment.
  String? resolveLogo(PartnerAssets assets, {required Brightness brightness}) {
    if (brightness == Brightness.dark) {
      return assets.darkLogoAssetPath ?? assets.logoAssetPath;
    }
    return assets.lightLogoAssetPath ?? assets.logoAssetPath;
  }

  /// Returns the hero image path for use in detail sheets.
  String? resolveHero(PartnerAssets assets) => assets.heroImageAssetPath;

  /// Returns the campaign banner path.
  String? resolveBanner(PartnerAssets assets) => assets.bannerAssetPath;

  /// Eagerly loads the bundled manifest so it is available synchronously
  /// to resolution methods. Call once during app startup (injection.dart).
  ///
  /// Sprint 4: extend this to also fetch the CDN manifest and cache overrides.
  Future<void> initialize() async {
    try {
      final raw = await rootBundle.loadString('assets/data/partner_assets.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      _manifestVersion = data['version'] as String? ?? 'unknown';
      // Sprint 4: parse 'partners' map and populate _cdnOverrides
    } catch (_) {
      // Non-fatal: manifest missing or malformed → all paths remain null → fallback renders.
    }
  }

  String _manifestVersion = 'unloaded';
  String get manifestVersion => _manifestVersion;
}
