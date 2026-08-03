// Defines the Money value object — monetary amounts always carry their currency.

import 'package:flutter/foundation.dart';
import 'currency.dart';

/// An immutable monetary value. Money is never a bare double; it always carries its currency.
@immutable
class Money {
  final num amount;
  final Currency currency;

  const Money({required this.amount, required this.currency});

  /// Zero INR — the default monetary zero.
  static const Money zero = Money(amount: 0, currency: Currency.inr);

  /// Zero for any given currency.
  static Money zeroOf(Currency currency) => Money(amount: 0, currency: currency);

  bool get isZero => amount == 0;
  bool get isPositive => amount > 0;
  bool get isNegative => amount < 0;

  Money operator +(Money other) {
    assert(other.currency == currency,
        'Cannot add Money with different currencies: $currency vs ${other.currency}');
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    assert(other.currency == currency,
        'Cannot subtract Money with different currencies: $currency vs ${other.currency}');
    return Money(amount: amount - other.amount, currency: currency);
  }

  Money operator *(num factor) => Money(amount: amount * factor, currency: currency);

  bool operator <(Money other) {
    assert(other.currency == currency, 'Cannot compare Money with different currencies');
    return amount < other.amount;
  }

  bool operator >(Money other) {
    assert(other.currency == currency, 'Cannot compare Money with different currencies');
    return amount > other.amount;
  }

  bool operator <=(Money other) {
    assert(other.currency == currency, 'Cannot compare Money with different currencies');
    return amount <= other.amount;
  }

  bool operator >=(Money other) {
    assert(other.currency == currency, 'Cannot compare Money with different currencies');
    return amount >= other.amount;
  }

  /// Formats as e.g. "₹3,000" or "₹1,23,456".
  String format() {
    final sym = currency.symbol;
    final absAmount = amount.abs();
    final intPart = absAmount.toInt();
    final fracPart = absAmount - intPart;

    String formatted = _formatIndian(intPart);
    if (fracPart > 0) {
      final cents = (fracPart * 100).round().toString().padLeft(2, '0');
      formatted = '$formatted.$cents';
    }
    return amount < 0 ? '-$sym$formatted' : '$sym$formatted';
  }

  /// Indian number formatting (e.g. 1,23,456).
  String _formatIndian(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final groups = <String>[];
    for (var i = rest.length; i > 0; i -= 2) {
      groups.add(rest.substring(i < 2 ? 0 : i - 2, i));
    }
    return '${groups.reversed.join(',')}'
        ',$last3';
  }

  Money copyWith({num? amount, Currency? currency}) =>
      Money(amount: amount ?? this.amount, currency: currency ?? this.currency);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Money && other.amount == amount && other.currency == currency);

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => format();
}
