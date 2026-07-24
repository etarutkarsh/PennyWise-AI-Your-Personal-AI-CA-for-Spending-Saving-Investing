class ParsedSmsTransaction {
  final double amount;
  final String direction; // DEBIT | CREDIT
  final String? merchant;
  final String? accountLast4;
  final DateTime transactionDate;

  const ParsedSmsTransaction({
    required this.amount,
    required this.direction,
    this.merchant,
    this.accountLast4,
    required this.transactionDate,
  });
}

class SmsParserService {
  /// Parses common Indian bank SMS formats.
  /// Returns null if the message doesn't look like a transaction SMS.
  static ParsedSmsTransaction? parse(String smsBody) {
    final body = smsBody.toLowerCase();

    // Must contain money indicators
    if (!body.contains('rs') && !body.contains('inr') && !body.contains('₹')) {
      return null;
    }

    // Must contain debit/credit/transaction keywords
    final isDebit = body.contains('debited') ||
        body.contains('debit') ||
        body.contains('withdrawn') ||
        body.contains('paid') ||
        body.contains('purchase') ||
        body.contains('spent');
    final isCredit = body.contains('credited') ||
        body.contains('credit') ||
        body.contains('received') ||
        body.contains('deposited');

    if (!isDebit && !isCredit) return null;

    final amount = _extractAmount(smsBody);
    if (amount == null || amount <= 0) return null;

    return ParsedSmsTransaction(
      amount: amount,
      direction: isDebit ? 'DEBIT' : 'CREDIT',
      merchant: _extractMerchant(smsBody),
      accountLast4: _extractAccount(smsBody),
      transactionDate: DateTime.now(),
    );
  }

  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+(?:\.\d{2})?)'),
      RegExp(r'([\d,]+(?:\.\d{2})?)\s*(?:Rs\.?|INR|₹)'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        return double.tryParse(m.group(1)!.replaceAll(',', ''));
      }
    }
    return null;
  }

  static String? _extractMerchant(String text) {
    // "at Swiggy", "to Zomato", "at merchant AMAZON"
    final patterns = [
      RegExp(r'(?:at|to|from|merchant)\s+([A-Z][A-Za-z0-9\s]{2,30})',
          caseSensitive: false),
      RegExp(r'UPI-([A-Za-z0-9@._-]{3,30})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final name = m.group(1)!.trim();
        if (name.length > 2 && !name.toLowerCase().contains('account')) {
          return name;
        }
      }
    }
    return null;
  }

  static String? _extractAccount(String text) {
    final m = RegExp(r'(?:a/c|acct|account|card)[\s*x]*(\d{4})',
            caseSensitive: false)
        .firstMatch(text);
    return m?.group(1);
  }

  /// Returns true if this looks like a bank transaction SMS
  static bool isBankSms(String sender, String body) {
    final knownSenders = [
      'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'yes bank', 'pnb', 'bob',
      'canara', 'idbi', 'federal', 'rbl', 'idfc', 'boi', 'union'
    ];
    final senderLower = sender.toLowerCase();
    if (knownSenders.any((s) => senderLower.contains(s))) return true;
    return body.toLowerCase().contains('your account') &&
        (body.toLowerCase().contains('debited') ||
            body.toLowerCase().contains('credited'));
  }
}
