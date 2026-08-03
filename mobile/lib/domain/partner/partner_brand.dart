import 'package:flutter/foundation.dart';

import 'partner_assets.dart';

/// Identity and branding for a financial partner institution.
///
/// Separated from [PartnerProgram] so one partner can offer many products
/// (HDFC RD, HDFC FD, HDFC Home Loan) without duplicating brand data.
///
/// Colors stored as hex ints so the domain stays free of Flutter's [Color].
/// Presentation layer wraps them: Color(brand.primaryColorHex).
@immutable
class PartnerBrand {
  const PartnerBrand({
    required this.id,
    required this.displayName,
    required this.legalName,
    required this.shortName,
    required this.primaryColorHex,
    required this.darkColorHex,
    required this.assets,
    required this.trustStatement,
    this.website,
    required this.regulatedEntity,
    this.country = 'IN',
  });

  /// Stable identifier, lowercase ASCII: 'hdfc', 'nippon', 'jar'.
  final String id;

  /// Display name shown in UI: 'HDFC Bank', 'Nippon India MF'.
  final String displayName;

  /// Full legal name for disclosures: 'HDFC Bank Limited'.
  final String legalName;

  /// Ultra-short name for tight UI slots: 'HDFC', 'jar', 'fi'.
  final String shortName;

  /// Brand primary color as ARGB hex int — use Color(primaryColorHex) in widgets.
  final int primaryColorHex;

  /// Darker variant for gradient ends — use Color(darkColorHex) in widgets.
  final int darkColorHex;

  final PartnerAssets assets;

  /// Fiduciary context for this partner — shown alongside any recommendation.
  final String trustStatement;

  final String? website;

  /// True if this entity is regulated by SEBI / RBI / IRDAI.
  final bool regulatedEntity;

  /// ISO-3166 alpha-2 country code. Defaults to 'IN'.
  final String country;

  PartnerBrand copyWith({
    String? displayName,
    String? legalName,
    String? shortName,
    int? primaryColorHex,
    int? darkColorHex,
    PartnerAssets? assets,
    String? trustStatement,
    String? website,
    bool? regulatedEntity,
    String? country,
  }) =>
      PartnerBrand(
        id: id,
        displayName: displayName ?? this.displayName,
        legalName: legalName ?? this.legalName,
        shortName: shortName ?? this.shortName,
        primaryColorHex: primaryColorHex ?? this.primaryColorHex,
        darkColorHex: darkColorHex ?? this.darkColorHex,
        assets: assets ?? this.assets,
        trustStatement: trustStatement ?? this.trustStatement,
        website: website ?? this.website,
        regulatedEntity: regulatedEntity ?? this.regulatedEntity,
        country: country ?? this.country,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PartnerBrand && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PartnerBrand($id — $displayName)';
}
