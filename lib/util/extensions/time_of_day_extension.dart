import 'package:flutter/material.dart';

extension TimeOfDayExtension on TimeOfDay {
  bool isBefore(TimeOfDay other) {
    return hour < other.hour || (hour == other.hour && minute < other.minute);
  }

  bool isAfter(TimeOfDay other) {
    return hour > other.hour || (hour == other.hour && minute > other.minute);
  }

  bool isAtSameMomentAs(TimeOfDay other) {
    return hour == other.hour && minute == other.minute;
  }

  String get formatted {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';
  }

  Duration getDurationUntil(TimeOfDay other) {
    final Duration duration = Duration(
      hours: other.hour - hour,
      minutes: other.minute - minute,
    );
    return duration.isNegative ? duration + const Duration(days: 1) : duration;
  }
}
