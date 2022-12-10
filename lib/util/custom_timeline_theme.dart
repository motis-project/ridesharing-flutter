import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

class CustomTimelineTheme {
  static TimelineThemeData of(BuildContext context) {
    return TimelineTheme.of(context).copyWith(
      nodePosition: 0,
      nodeItemOverlap: true,
      connectorTheme: ConnectorThemeData(color: Theme.of(context).colorScheme.secondary, thickness: 5.0),
      indicatorTheme: IndicatorThemeData(
        color: Theme.of(context).colorScheme.onSurface,
        size: 15.0,
      ),
    );
  }
}

class CustomTimelineThemeForBuilder {
  static TimelineThemeData of(BuildContext context) {
    return CustomTimelineTheme.of(context).copyWith(
      indicatorTheme: CustomTimelineTheme.of(context).indicatorTheme.copyWith(
            position: 0.5,
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
