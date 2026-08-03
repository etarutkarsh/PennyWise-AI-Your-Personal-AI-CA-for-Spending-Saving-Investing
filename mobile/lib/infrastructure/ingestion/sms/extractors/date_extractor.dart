import '../../../../domain/ingestion/field_extraction.dart';

/// Extracts the transaction date from a bank SMS.
///
/// Supports DD-MM-YYYY, DD Mon YYYY, Mon DD YYYY, and compact DDMMYY formats.
/// Does NOT fall back to DateTime.now() — returns missing if no date is found.
class DateExtractor {
  const DateExtractor();

  static const _fieldName = 'date';

  static const _monthNames = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
    'may': 5, 'jun': 6, 'jul': 7, 'aug': 8,
    'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
  };

  // Pattern 1: DD-MM-YYYY or DD/MM/YY
  static final _dmyPattern = RegExp(
    r'(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})',
    caseSensitive: false,
  );

  // Pattern 2: DD Mon YYYY  e.g. 04 Jan 2025 or 04-Jan-2025
  static final _dMonYPattern = RegExp(
    r'(\d{1,2})[\s\-](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*[\s,\-]+(\d{2,4})',
    caseSensitive: false,
  );

  // Pattern 3: Mon DD YYYY  e.g. Jan 4, 2025
  static final _monDYPattern = RegExp(
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{4})',
    caseSensitive: false,
  );

  // Pattern 4: compact DDMMYY  e.g. 040125
  static final _compactPattern = RegExp(r'(\d{2})(\d{2})(\d{2,4})');

  FieldExtraction<DateTime> extract(String text) {
    // Pattern 1: DD-MM-YYYY
    final m1 = _dmyPattern.firstMatch(text);
    if (m1 != null) {
      final day = int.tryParse(m1.group(1)!);
      final month = int.tryParse(m1.group(2)!);
      var yearRaw = int.tryParse(m1.group(3)!);
      if (day != null && month != null && yearRaw != null) {
        if (yearRaw < 100) yearRaw += 2000;
        if (_isValidDmy(day, month, yearRaw)) {
          final date = DateTime(yearRaw, month, day);
          return _build(date, 0.90, 'dd_mm_yyyy', m1.group(0)!);
        }
      }
    }

    // Pattern 2: DD Mon YYYY
    final m2 = _dMonYPattern.firstMatch(text);
    if (m2 != null) {
      final day = int.tryParse(m2.group(1)!);
      final month = _monthNames[m2.group(2)!.toLowerCase().substring(0, 3)];
      var yearRaw = int.tryParse(m2.group(3)!);
      if (day != null && month != null && yearRaw != null) {
        if (yearRaw < 100) yearRaw += 2000;
        if (_isValidDmy(day, month, yearRaw)) {
          final date = DateTime(yearRaw, month, day);
          return _build(date, 0.95, 'dd_mon_yyyy', m2.group(0)!);
        }
      }
    }

    // Pattern 3: Mon DD YYYY
    final m3 = _monDYPattern.firstMatch(text);
    if (m3 != null) {
      final month = _monthNames[m3.group(1)!.toLowerCase().substring(0, 3)];
      final day = int.tryParse(m3.group(2)!);
      final year = int.tryParse(m3.group(3)!);
      if (day != null && month != null && year != null) {
        if (_isValidDmy(day, month, year)) {
          final date = DateTime(year, month, day);
          return _build(date, 0.95, 'mon_dd_yyyy', m3.group(0)!);
        }
      }
    }

    // Pattern 4: compact DDMMYY
    final m4 = _compactPattern.firstMatch(text);
    if (m4 != null) {
      final day = int.tryParse(m4.group(1)!);
      final month = int.tryParse(m4.group(2)!);
      var yearRaw = int.tryParse(m4.group(3)!);
      if (day != null && month != null && yearRaw != null) {
        if (yearRaw < 100) yearRaw += 2000;
        if (_isValidDmy(day, month, yearRaw)) {
          final date = DateTime(yearRaw, month, day);
          return _build(date, 0.70, 'ddmmyy_compact', m4.group(0)!);
        }
      }
    }

    return FieldExtraction<DateTime>.missing(_fieldName);
  }

  FieldExtraction<DateTime> _build(
    DateTime date,
    double confidence,
    String ruleName,
    String raw,
  ) {
    final now = DateTime.now();
    final List<String> notes = [];

    if (date.isAfter(now.add(const Duration(days: 7)))) {
      notes.add('Date in future — likely parse error');
    }
    if (date.isBefore(now.subtract(const Duration(days: 365 * 5)))) {
      notes.add('Date very old — verify');
    }

    final ambiguity = notes.isNotEmpty ? ' ${notes.join('; ')}' : '';

    return FieldExtraction<DateTime>(
      value: date,
      confidence: confidence,
      decision: ParseDecision(
        fieldName: _fieldName,
        type: ParseDecisionType.regexMatch,
        ruleApplied: ruleName,
        reason: '$ruleName matched, date=${date.toIso8601String().substring(0, 10)}$ambiguity',
        confidence: confidence,
        rawExtracted: raw,
      ),
    );
  }

  bool _isValidDmy(int day, int month, int year) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 1900 || year > 2100) return false;
    return true;
  }
}
