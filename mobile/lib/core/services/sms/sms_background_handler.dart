import 'dart:convert';
import 'package:another_telephony/telephony.dart' as tel;
import 'package:shared_preferences/shared_preferences.dart';

const String kSmsBackgroundQueueKey = 'sms_background_queue';

/// Called by Android when an SMS arrives and the app is in the background or killed.
/// Runs in a separate Dart isolate — no access to the main DI container.
/// Queues the raw SMS for processing when the app next comes to foreground.
@pragma('vm:entry-point')
Future<void> onBackgroundSmsReceived(tel.SmsMessage message) async {
  final body = message.body ?? '';
  final sender = message.address ?? '';
  if (body.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final queue = prefs.getStringList(kSmsBackgroundQueueKey) ?? [];
  queue.add(jsonEncode({'body': body, 'sender': sender}));
  await prefs.setStringList(kSmsBackgroundQueueKey, queue);
}
