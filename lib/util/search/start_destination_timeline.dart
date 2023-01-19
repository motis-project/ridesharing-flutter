import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

import '../custom_timeline_theme.dart';
import 'address_search_field.dart';
import 'address_suggestion.dart';

class StartDestinationTimeline extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final void Function(AddressSuggestion)? onStartSelected;
  final void Function(AddressSuggestion)? onDestinationSelected;

  const StartDestinationTimeline({
    super.key,
    required this.startController,
    required this.destinationController,
    this.onStartSelected,
    this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FixedTimeline(theme: CustomTimelineTheme.of(context), children: <Widget>[
      TimelineTile(
        contents: Padding(
          padding: const EdgeInsets.all(4.0),
          child: AddressSearchField.start(controller: startController, onSelected: onStartSelected),
        ),
        node: const TimelineNode(
          indicator: CustomOutlinedDotIndicator(),
          endConnector: CustomSolidLineConnector(),
        ),
      ),
      TimelineTile(
        contents: Padding(
          padding: const EdgeInsets.all(4.0),
          child: AddressSearchField.destination(controller: destinationController, onSelected: onDestinationSelected),
        ),
        node: const TimelineNode(
          indicator: CustomOutlinedDotIndicator(),
          startConnector: CustomSolidLineConnector(),
        ),
      ),
    ]);
  }
}
