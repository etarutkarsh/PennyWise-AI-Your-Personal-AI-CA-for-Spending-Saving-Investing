// Defines the Percentage value object for rates stored as 0.0–1.0 fractions.

import 'package:flutter/foundation.dart';

/// An immutable percentage value stored internally as a 0.0–1.0 fraction.
@immutable
class Percentage {
  /// Internal value in range 0.0–1.0.
  final double value;

  const Percentage(this.value)
      : assert(value >= 0.0 && value <= 1.0,
            'Percentage value must be between 0.0 and 1.0, got $value');

  /// Creates from a human-readable percent (e.g. 82.0 → 0.82).
  factory Percentage.fromPercent(double percent) => Percentage(percent / 100.0);

  static const Percentage zero = Percentage(0.0);
  static const Percentage hundred = Percentage(1.0);

  /// Returns value as a human-readable percent (e.g. 0.82 → 82.0).
  double get toPercent => value * 100.0;

  /// Formats as e.g. "82%".
  String format({int decimals = 0}) {
    final pct = toPercent;
    if (decimals == 0) return '${pct.round()}%';
    return '${pct.toStringAsFixed(decimals)}%';
  }

  Percentage operator +(Percentage other) =>
      Percentage((value + other.value).clamp(0.0, 1.0));

  Percentage operator -(Percentage other) =>
      Percentage((value - other.value).clamp(0.0, 1.0));

  Percentage operator *(double factor) =>
      Percentage((value * factor).clamp(0.0, 1.0));

  bool operator <(Percentage other) => value < other.value;
  bool operator >(Percentage other) => value > other.value;
  bool operator <=(Percentage other) => value <= other.value;
  bool operator >=(Percentage other) => value >= other.value;

  Percentage copyWith({double? value}) => Percentage(value ?? this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Percentage && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => format();
}
