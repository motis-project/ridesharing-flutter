import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

extension TimeOfDayExtension on TimeOfDay {
  bool isBefore(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  String get formatted {
    final DateTime dateTime = DateTime(0, 0, 0, hour, minute).toUtc();
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  Duration getDurationUntil(TimeOfDay other) {
    final Duration duration = Duration(
      hours: other.hour - hour,
      minutes: other.minute - minute,
    );
    return duration.isNegative ? duration + const Duration(days: 1) : duration;
  }
}
