import 'package:flutter/foundation.dart';

/// Canonical category for a merchant.
/// More granular than the UI category — used by CommitmentEngine and Behavioral Engine.
enum MerchantCategory {
  streaming,
  musicStreaming,
  cloudStorage,
  softwareSubscription,
  aiServices,
  food,
  groceries,
  transport,
  fuel,
  travel,
  shopping,
  bills,
  electricity,
  internet,
  mobile,
  insurance,
  investment,
  loanEmi,
  creditCard,
  bank,
  education,
  health,
  fitness,
  entertainment,
  government,
  epf,
  salary,
  rent,
  other,
}

extension MerchantCategoryExtension on MerchantCategory {
  String get displayName {
    switch (this) {
      case MerchantCategory.streaming:            return 'Streaming';
      case MerchantCategory.musicStreaming:        return 'Music';
      case MerchantCategory.cloudStorage:          return 'Cloud Storage';
      case MerchantCategory.softwareSubscription:  return 'Software';
      case MerchantCategory.aiServices:            return 'AI Services';
      case MerchantCategory.food:                  return 'Food';
      case MerchantCategory.groceries:             return 'Groceries';
      case MerchantCategory.transport:             return 'Transport';
      case MerchantCategory.fuel:                  return 'Fuel';
      case MerchantCategory.travel:                return 'Travel';
      case MerchantCategory.shopping:              return 'Shopping';
      case MerchantCategory.bills:                 return 'Bills';
      case MerchantCategory.electricity:           return 'Electricity';
      case MerchantCategory.internet:              return 'Internet';
      case MerchantCategory.mobile:                return 'Mobile';
      case MerchantCategory.insurance:             return 'Insurance';
      case MerchantCategory.investment:            return 'Investment';
      case MerchantCategory.loanEmi:               return 'Loan EMI';
      case MerchantCategory.creditCard:            return 'Credit Card';
      case MerchantCategory.bank:                  return 'Bank';
      case MerchantCategory.education:             return 'Education';
      case MerchantCategory.health:                return 'Health';
      case MerchantCategory.fitness:               return 'Fitness';
      case MerchantCategory.entertainment:         return 'Entertainment';
      case MerchantCategory.government:            return 'Government';
      case MerchantCategory.epf:                   return 'EPF/NPS';
      case MerchantCategory.salary:                return 'Salary';
      case MerchantCategory.rent:                  return 'Rent';
      case MerchantCategory.other:                 return 'Other';
    }
  }

  bool get isSubscription =>
      this == MerchantCategory.streaming ||
      this == MerchantCategory.musicStreaming ||
      this == MerchantCategory.cloudStorage ||
      this == MerchantCategory.softwareSubscription ||
      this == MerchantCategory.aiServices ||
      this == MerchantCategory.fitness;
}

/// Canonical merchant entity — the output of the Financial Identity Resolution Engine.
/// All aliases resolve to a single MerchantProfile.
///
/// Example: "NETFLIX", "Netflix", "NETFLIX-MUM", "NETFLIX INDIA", "Netflix.com"
/// all resolve to MerchantProfile(id: 'netflix', canonicalName: 'Netflix').
@immutable
class MerchantProfile {
  const MerchantProfile({
    required this.id,
    required this.canonicalName,
    required this.category,
    required this.aliases,
    this.isSubscription = false,
    this.isInvestment = false,
    this.isDebt = false,
    this.isInsurance = false,
    this.country = 'IN',
    this.website,
    this.typicalMonthlyAmount,
    this.upiHandles = const {},
    this.confidence = 1.0,
  }) : assert(confidence >= 0.0 && confidence <= 1.0);

  /// Stable unique id (snake_case, e.g. 'netflix', 'hdfc_home_loan').
  final String id;

  /// Display name shown in UI (e.g. 'Netflix', 'HDFC Bank').
  final String canonicalName;

  final MerchantCategory category;

  /// All known alias strings this merchant appears as in bank SMS/statements.
  final List<String> aliases;

  final bool isSubscription;
  final bool isInvestment;
  final bool isDebt;
  final bool isInsurance;
  final String country;
  final String? website;

  /// Typical monthly charge — null for variable merchants.
  final double? typicalMonthlyAmount;

  /// UPI VPA handles used by this merchant (for UPI AutoPay detection).
  final Set<String> upiHandles;

  /// Confidence that this profile is accurate (0.0–1.0).
  final double confidence;

  bool get isKnown => true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MerchantProfile && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MerchantProfile($id → $canonicalName)';
}

/// Returned when no MerchantProfile can be resolved from the raw merchant string.
@immutable
class UnknownMerchantProfile extends MerchantProfile {
  const UnknownMerchantProfile(String rawName)
      : super(
          id: 'unknown',
          canonicalName: rawName,
          category: MerchantCategory.other,
          aliases: const [],
          confidence: 0.30,
        );

  @override
  bool get isKnown => false;
}
