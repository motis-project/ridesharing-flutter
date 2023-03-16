import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

// We need to write this custom class to define our timeline theme and use the "of" method naturally.
// ignore: avoid_classes_with_only_static_members
class CustomTimelineTheme {
  static TimelineThemeData of(BuildContext context, {bool forBuilder = false}) {
    return TimelineTheme.of(context).copyWith(
      nodePosition: 0,
      nodeItemOverlap: true,
      connectorTheme: ConnectorThemeData(color: Theme.of(context).colorScheme.secondary, thickness: 5.0),
      indicatorTheme: IndicatorThemeData(
        color: Theme.of(context).colorScheme.onSurface,
        size: 15.0,
        position: forBuilder ? 0.5 : null,
      ),
    );
  }
}

class CustomOutlinedDotIndicator extends StatelessWidget {
  const CustomOutlinedDotIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return OutlinedDotIndicator(
      color: CustomTimelineTheme.of(context).indicatorTheme.color,
      backgroundColor: Theme.of(context).colorScheme.surface,
    );
  }
}

class CustomSolidLineConnector extends StatelessWidget {
  const CustomSolidLineConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidLineConnector(
      color: CustomTimelineTheme.of(context).connectorTheme.color,
    );
  }
}
