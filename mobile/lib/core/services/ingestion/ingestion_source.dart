import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

// ─── Enums ────────────────────────────────────────────────────────────────────

enum IngestionSourceType {
  sms,               // Android SMS inbox — fastest, no account linking required
  accountAggregator, // RBI AA framework (Setu/Finvu) — most complete, consent-based
  email,             // Gmail/Outlook receipt parsing — catches ChatGPT, Adobe, etc.
  pdf,               // Bank statement PDF upload — universal, works on all platforms
  csv,               // CSV statement import — for users who prefer data exports
  manual,            // Manual transaction entry — always available
}

enum IngestionAvailability {
  available,         // Ready to use
  notConfigured,     // Integration not set up yet (AA, email)
  permissionDenied,  // User denied permission (SMS)
  platformUnsupported, // iOS for SMS
  comingSoon,        // Planned but not built
}

// ─── Data Model ───────────────────────────────────────────────────────────────

/// Unified event model all ingestion sources produce.
/// Downstream: → TransactionNormalizer → TransactionEntity → CommitmentEngine
class RawFinancialEvent {
  const RawFinancialEvent({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.direction,
    required this.rawMerchant,
    required this.source,
    this.paymentRail,       // NACH, UPI, ECS, CARD, etc.
    this.accountLast4,
    this.sourceRef,         // SMS ID, email message-id, AA txn ID
    this.confidence = 1.0,
    this.rawText,           // original message/line for debugging
  });

  final String id;
  final DateTime timestamp;
  final double amount;
  final String direction;           // DEBIT | CREDIT
  final String rawMerchant;
  final IngestionSourceType source;
  final String? paymentRail;
  final String? accountLast4;
  final String? sourceRef;
  final double confidence;
  final String? rawText;
}

/// Snapshot of a source's current state — used by the Setup UI.
class IngestionSourceStatus {
  const IngestionSourceStatus({
    required this.sourceType,
    required this.availability,
    this.lastSync,
    this.transactionCount = 0,
    this.errorMessage,
    this.accountLabel,
  });

  final IngestionSourceType sourceType;
  final IngestionAvailability availability;
  final DateTime? lastSync;
  final int transactionCount;
  final String? errorMessage;
  final String? accountLabel;   // "HDFC **1234" or "user@gmail.com"

  bool get isUsable => availability == IngestionAvailability.available;
}

// ─── Abstract Source ──────────────────────────────────────────────────────────

abstract class IngestionSource {
  String get name;
  String get description;
  String get icon;
  IngestionSourceType get sourceType;

  /// Whether this source is technically available on the current platform.
  bool get isPlatformSupported;

  Future<IngestionSourceStatus> checkStatus();

  /// Fetch raw events in [from]..[to] range.
  Future<List<RawFinancialEvent>> fetch({
    required DateTime from,
    required DateTime to,
  });
}

// ─── Concrete Sources ─────────────────────────────────────────────────────────

/// SMS ingestion — Android only, privacy-first, local parsing.
///
/// Implementation: see `SmsImportScreen` + `SmsParserService`.
/// This class exposes the metadata the Setup UI needs without importing
/// the full SMS parser.
class SmsIngestionSource extends IngestionSource {
  @override
  String get name => 'SMS Import';

  @override
  String get description =>
      'Reads your bank SMS automatically. Detects UPI, NACH, card payments and more.';

  @override
  String get icon => '📩';

  @override
  IngestionSourceType get sourceType => IngestionSourceType.sms;

  @override
  bool get isPlatformSupported => !kIsWeb && Platform.isAndroid;

  @override
  Future<IngestionSourceStatus> checkStatus() async {
    if (!isPlatformSupported) {
      return IngestionSourceStatus(
        sourceType: sourceType,
        availability: IngestionAvailability.platformUnsupported,
        errorMessage: 'SMS reading is only available on Android. '
            'Use Bank Statement or Account Aggregator instead.',
      );
    }
    // Actual permission check is done inside SmsImportScreen
    // to keep this class free of permission_handler imports.
    return IngestionSourceStatus(
      sourceType: sourceType,
      availability: IngestionAvailability.available,
    );
  }

  @override
  Future<List<RawFinancialEvent>> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    // Implemented in SmsImportScreen (uses flutter_sms_inbox).
    // Future: extract SmsParserService logic here and return RawFinancialEvent list.
    return [];
  }
}

/// Account Aggregator — RBI-regulated, consent-based bank data sharing.
///
/// Integration: Setu AA SDK (already in enterprise roadmap).
/// Gives 12–24 months of complete transaction history + mandate registry.
class AccountAggregatorSource extends IngestionSource {
  @override
  String get name => 'Connect Bank';

  @override
  String get description =>
      'Link your bank via RBI Account Aggregator. '
      'Get 12 months of complete history. Consent revocable anytime.';

  @override
  String get icon => '🏦';

  @override
  IngestionSourceType get sourceType => IngestionSourceType.accountAggregator;

  @override
  bool get isPlatformSupported => true; // Available on all platforms

  @override
  Future<IngestionSourceStatus> checkStatus() async {
    return IngestionSourceStatus(
      sourceType: sourceType,
      availability: IngestionAvailability.comingSoon,
      errorMessage: 'Bank connection via Account Aggregator coming soon.',
    );
  }

  @override
  Future<List<RawFinancialEvent>> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    throw UnimplementedError('AA integration not yet built.');
  }
}

/// Email receipt parsing — catches subscriptions missing from bank SMS.
///
/// Target: ChatGPT, Claude, Adobe, Canva, AWS, GitHub, App Store purchases
/// that appear as generic merchants in bank statements.
/// Requires Gmail OAuth or IMAP credentials.
class EmailIngestionSource extends IngestionSource {
  @override
  String get name => 'Email Receipts';

  @override
  String get description =>
      'Parse Gmail or Outlook for subscription receipts. '
      'Detects ChatGPT, Adobe, Canva, AWS and more.';

  @override
  String get icon => '✉️';

  @override
  IngestionSourceType get sourceType => IngestionSourceType.email;

  @override
  bool get isPlatformSupported => true;

  @override
  Future<IngestionSourceStatus> checkStatus() async {
    return IngestionSourceStatus(
      sourceType: sourceType,
      availability: IngestionAvailability.comingSoon,
      errorMessage: 'Email parsing coming soon.',
    );
  }

  @override
  Future<List<RawFinancialEvent>> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    throw UnimplementedError('Email parsing not yet built.');
  }
}

/// Bank statement PDF/CSV import — universal, works on all platforms including iOS.
///
/// Supported: SBI, HDFC, ICICI, Axis, Kotak, Yes Bank, IDFC, AU Small Finance.
class StatementImportSource extends IngestionSource {
  @override
  String get name => 'Import Statement';

  @override
  String get description =>
      'Upload a PDF or CSV bank statement. '
      'Works on iPhone. Covers all banks.';

  @override
  String get icon => '📄';

  @override
  IngestionSourceType get sourceType => IngestionSourceType.pdf;

  @override
  bool get isPlatformSupported => true;

  @override
  Future<IngestionSourceStatus> checkStatus() async {
    return IngestionSourceStatus(
      sourceType: sourceType,
      availability: IngestionAvailability.comingSoon,
      errorMessage: 'Statement import coming soon.',
    );
  }

  @override
  Future<List<RawFinancialEvent>> fetch({
    required DateTime from,
    required DateTime to,
  }) async {
    throw UnimplementedError('Statement import not yet built.');
  }
}

// ─── Registry ─────────────────────────────────────────────────────────────────

/// All ingestion sources, in recommended priority order.
///
/// Android: SMS is fastest. iPhone: AA is primary, PDF is fallback.
final List<IngestionSource> allIngestionSources = [
  SmsIngestionSource(),
  AccountAggregatorSource(),
  EmailIngestionSource(),
  StatementImportSource(),
];
