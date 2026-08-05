import 'package:flutter/foundation.dart';

@immutable
class TimelineMonth {
  const TimelineMonth({
    required this.year,
    required this.month,
    required this.totalAmount,
    required this.spikeLabel,
    required this.isCurrentMonth,
  });

  final int year;
  final int month;
  final double totalAmount;
  final String spikeLabel;
  final bool isCurrentMonth;

  String get shortLabel {
    const m = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return m[month - 1];
  }

  String get fullLabel {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[month - 1]} $year';
  }
}
