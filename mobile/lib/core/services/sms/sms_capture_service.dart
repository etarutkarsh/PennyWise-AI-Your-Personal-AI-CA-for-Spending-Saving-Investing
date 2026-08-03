import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:another_telephony/telephony.dart' as tel;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/engines/sms_parser_registry.dart';
import '../../../domain/engines/sms_validation_engine.dart';
import '../ingestion/ingestion_source.dart';
import 'sms_background_handler.dart';

class SmsCaptureService {
  SmsCaptureService({
    required SmsParserRegistry parserRegistry,
    required SmsValidationEngine validationEngine,
  })  : _registry = parserRegistry,
        _validation = validationEngine;

  final SmsParserRegistry _registry;
  final SmsValidationEngine _validation;
  final _liveController = StreamController<RawFinancialEvent>.broadcast();

  Stream<RawFinancialEvent> get liveTransactions => _liveController.stream;

  // Pipeline: one raw SMS message → RawFinancialEvent (or null if not financial)
  RawFinancialEvent? processMessage(String body, String sender) {
    if (body.trim().isEmpty) return null;
    final result = _registry.parse(body, sender);
    final validation = _validation.validate(result, sender);
    if (!validation.isUsable) return null;
    if (!result.isUsable) return null;
    final senderNorm = sender.isEmpty ? 'unknown' : sender;
    final tsMs = result.transactionDate?.millisecondsSinceEpoch ??
        DateTime.now().millisecondsSinceEpoch;
    return RawFinancialEvent(
      id: '${senderNorm}_${tsMs}_${result.amount}',
      timestamp: result.transactionDate ?? DateTime.now(),
      amount: result.amount!,
      direction: result.direction!,
      rawMerchant: result.rawMerchant ?? 'Unknown',
      source: IngestionSourceType.sms,
      paymentRail: result.paymentRail?.name,
      accountLast4: result.accountLast4,
      sourceRef: result.referenceId,
      confidence: result.overallConfidence,
      rawText: body,
    );
  }

  // Bulk read from Android inbox — caller must have READ_SMS permission
  Future<List<RawFinancialEvent>> fetchInbox({
    required DateTime from,
    required DateTime to,
  }) async {
    final query = SmsQuery();
    final messages = await query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 1000,
    );

    final events = <RawFinancialEvent>[];
    final seenKeys = <String>{};

    for (final msg in messages) {
      final body = msg.body ?? '';
      final sender = msg.address ?? '';
      final date = msg.date;
      if (date != null && (date.isBefore(from) || date.isAfter(to))) continue;

      final event = processMessage(body, sender);
      if (event == null) continue;

      final key = '${event.amount}_${event.direction}_'
          '${event.timestamp.year}'
          '${event.timestamp.month.toString().padLeft(2, '0')}'
          '${event.timestamp.day.toString().padLeft(2, '0')}';
      if (seenKeys.contains(key)) continue;
      seenKeys.add(key);
      events.add(event);
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  // Start foreground live listener + drain any SMS queued while app was killed
  Future<void> startListening() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await drainBackgroundQueue();
    tel.Telephony.instance.listenIncomingSms(
      onNewMessage: (tel.SmsMessage message) {
        final event =
            processMessage(message.body ?? '', message.address ?? '');
        if (event != null && !_liveController.isClosed) {
          _liveController.add(event);
        }
      },
      listenInBackground: true,
      onBackgroundMessage: onBackgroundSmsReceived,
    );
  }

  // Process SMS messages queued by the background handler
  Future<int> drainBackgroundQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(kSmsBackgroundQueueKey) ?? [];
    if (raw.isEmpty) return 0;
    int processed = 0;
    for (final entry in raw) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final event = processMessage(
          map['body'] as String? ?? '',
          map['sender'] as String? ?? '',
        );
        if (event != null && !_liveController.isClosed) {
          _liveController.add(event);
          processed++;
        }
      } catch (_) {}
    }
    await prefs.remove(kSmsBackgroundQueueKey);
    return processed;
  }

  void dispose() {
    if (!_liveController.isClosed) _liveController.close();
  }
}
