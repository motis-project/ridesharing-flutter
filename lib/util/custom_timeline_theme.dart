import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class CustomTimelineTheme {
  static TimelineThemeData of(BuildContext context) {
    return TimelineTheme.of(context).copyWith(
      nodePosition: 0.05,
      color: Colors.black,
    );
  }
}
