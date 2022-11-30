import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class CustomTimelineTheme {
  static TimelineThemeData of(BuildContext context) {
    return TimelineTheme.of(context).copyWith(
      nodePosition: 0.05,
      nodeItemOverlap: true,
      connectorTheme:
          const ConnectorThemeData(color: Color(0xffe6e7e9), thickness: 15.0),
      color: Colors.black,
    );
  }
}
