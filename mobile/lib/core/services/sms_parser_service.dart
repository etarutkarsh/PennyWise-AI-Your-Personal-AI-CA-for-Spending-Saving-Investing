class ParsedSmsTransaction {
  final double amount;
  final String direction; // DEBIT | CREDIT
  final String merchant;
  final String? accountLast4;
  final DateTime transactionDate;
  final String? paymentMethod; // UPI | CARD | NETBANKING | WALLET | null

  const ParsedSmsTransaction({
    required this.amount,
    required this.direction,
    required this.merchant,
    this.accountLast4,
    required this.transactionDate,
    this.paymentMethod,
  });
}

class SmsParserService {
  /// Parses a single bank SMS body. Returns null if it doesn't look financial.
  static ParsedSmsTransaction? parse(String smsBody) {
    final body = smsBody.toLowerCase();

    // Guard: must contain money keyword
    if (!body.contains('rs') && !body.contains('inr') && !body.contains('₹')) {
      return null;
    }

    // Direction detection
    final isDebit = body.contains('debited') ||
        body.contains('debit') ||
        body.contains('withdrawn') ||
        body.contains('paid') ||
        body.contains('purchase') ||
        body.contains('spent') ||
        body.contains('sent') ||
        body.contains('deducted');

    final isCredit = body.contains('credited') ||
        body.contains('credit') ||
        body.contains('received') ||
        body.contains('deposited') ||
        body.contains('added') ||
        body.contains('refund');

    // Must contain at least one transaction keyword
    if (!isDebit && !isCredit) return null;

    // Amount extraction
    final amount = _extractAmount(smsBody);
    if (amount == null || amount <= 0) return null;

    // Debit wins if both keywords match
    final direction = isDebit ? 'DEBIT' : 'CREDIT';

    return ParsedSmsTransaction(
      amount: amount,
      direction: direction,
      merchant: _extractMerchant(smsBody),
      accountLast4: _extractAccount(smsBody),
      transactionDate: _extractDate(smsBody),
      paymentMethod: _extractPaymentMethod(smsBody),
    );
  }

  /// Parses multiple SMS messages split by blank lines.
  static List<ParsedSmsTransaction> parseAll(String input) {
    final chunks = input.trim().split(RegExp(r'\n\n+'));
    final results = <ParsedSmsTransaction>[];
    for (final chunk in chunks) {
      final trimmed = chunk.trim();
      if (trimmed.isEmpty) continue;
      final parsed = parse(trimmed);
      if (parsed != null) results.add(parsed);
    }
    return results;
  }

  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{1,2})?)'),
      RegExp(r'([\d,]+(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        return double.tryParse(m.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  static DateTime _extractDate(String text) {
    // Pattern 1: DD-MM-YYYY or DD/MM/YY
    final p1 = RegExp(r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})');
    final m1 = p1.firstMatch(text);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!) ?? 1;
      final month = int.tryParse(m1.group(2)!) ?? 1;
      var year = int.tryParse(m1.group(3)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // Pattern 2: DD Mon YYYY  (e.g. "24 Jul 2026" or "24-Jul-2026")
    final monthNames = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final p2 = RegExp(
      r'(\d{1,2})[\s\-](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,\-]+(\d{2,4})',
      caseSensitive: false,
    );
    final m2 = p2.firstMatch(text);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!) ?? 1;
      final monthStr = m2.group(2)!.toLowerCase().substring(0, 3);
      final month = monthNames[monthStr] ?? 1;
      var year = int.tryParse(m2.group(3)!) ?? DateTime.now().year;
      if (year < 100) year += 2000;
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    // Pattern 3: Mon DD, YYYY  (e.g. "Jul 24, 2026")
    final p3 = RegExp(
      r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{4})',
      caseSensitive: false,
    );
    final m3 = p3.firstMatch(text);
    if (m3 != null) {
      final monthStr = m3.group(1)!.toLowerCase().substring(0, 3);
      final month = monthNames[monthStr] ?? 1;
      final day = int.tryParse(m3.group(2)!) ?? 1;
      final year = int.tryParse(m3.group(3)!) ?? DateTime.now().year;
      try {
        return DateTime(year, month, day);
      } catch (_) {}
    }

    return DateTime.now();
  }

  static String _extractMerchant(String text) {
    final patterns = [
      RegExp(
        r'(?:at|to merchant)\s+([A-Z][A-Za-z0-9&.\-\s]{2,28})(?:\s+on|\s+Avl|\s+Info|\.|,|$)',
        caseSensitive: false,
      ),
      RegExp(
        r'(?:to|from)\s+([A-Z][A-Za-z0-9&.\-\s]{2,25})(?:\s+on|\s+via|\s+Ref|\.|,|$)',
        caseSensitive: false,
      ),
      RegExp(r'UPI[- ]([A-Za-z0-9@._-]{3,30})'),
      RegExp(
        r'(?:trf to|transfer to)\s+([A-Za-z0-9\s]{3,25})',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final raw = m.group(1)!.trim();
        final cleaned = _cleanMerchant(raw);
        if (cleaned.isNotEmpty) return cleaned;
      }
    }
    return 'Unknown';
  }

  static String _cleanMerchant(String raw) {
    // Remove trailing stop-words
    var name = raw
        .replaceAll(RegExp(r'\s+(on|avl|info|via|ref)\s*$', caseSensitive: false), '')
        .trim();

    // Strip trailing punctuation
    name = name.replaceAll(RegExp(r'[,.\s]+$'), '').trim();

    if (name.isEmpty) return 'Unknown';

    final lower = name.toLowerCase();
    if (lower.contains('account') || lower.contains('a/c') || lower.contains('balance')) {
      return 'Unknown';
    }

    // Title case
    name = name.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join(' ');

    // Limit to 30 chars
    if (name.length > 30) name = name.substring(0, 30).trim();

    return name.isEmpty ? 'Unknown' : name;
  }

  static String? _extractAccount(String text) {
    final m = RegExp(r'(?:a/c|acct|account|card)[\s*x]*(\d{4})',
            caseSensitive: false)
        .firstMatch(text);
    return m?.group(1);
  }

  static String? _extractPaymentMethod(String text) {
    final body = text.toLowerCase();
    if (body.contains('upi') || body.contains('upi ref')) return 'UPI';
    if (body.contains('neft') || body.contains('imps') || body.contains('rtgs')) {
      return 'NETBANKING';
    }
    if (body.contains('card') || body.contains('pos') || body.contains('atm')) {
      return 'CARD';
    }
    if (body.contains('wallet') ||
        body.contains('paytm') ||
        body.contains('phonepe') ||
        body.contains('gpay')) {
      return 'WALLET';
    }
    return null;
  }

  /// Returns true if this looks like a bank transaction SMS.
  static bool isBankSms(String sender, String body) {
    final knownSenders = [
      'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'yes bank', 'pnb', 'bob',
      'canara', 'idbi', 'federal', 'rbl', 'idfc', 'boi', 'union',
    ];
    final senderLower = sender.toLowerCase();
    if (knownSenders.any((s) => senderLower.contains(s))) return true;
    return body.toLowerCase().contains('your account') &&
        (body.toLowerCase().contains('debited') ||
            body.toLowerCase().contains('credited'));
  }
}
