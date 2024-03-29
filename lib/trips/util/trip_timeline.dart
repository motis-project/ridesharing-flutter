import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../search/address_search_field.dart';
import '../../search/address_suggestion.dart';
import 'custom_timeline_theme.dart';

class TripTimeline extends StatelessWidget {
  final TextEditingController startController;
  final TextEditingController destinationController;
  final void Function(AddressSuggestion) onStartSelected;
  final void Function(AddressSuggestion) onDestinationSelected;
  final VoidCallback? onSwap;

  const TripTimeline({
    super.key,
    required this.startController,
    required this.destinationController,
    required this.onStartSelected,
    required this.onDestinationSelected,
    this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    Widget timeline = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: <Widget>[
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 4),
            child: AddressSearchField.start(controller: startController, onSelected: onStartSelected),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            endConnector: CustomSolidLineConnector(),
          ),
        ),
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 0, 0),
            child: AddressSearchField.destination(controller: destinationController, onSelected: onDestinationSelected),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            startConnector: CustomSolidLineConnector(),
          ),
        ),
      ],
    );
    if (onSwap != null) {
      timeline = Row(
        children: <Widget>[
          Expanded(
            child: timeline,
          ),
          IconButton(
            key: const Key('swapButton'),
            tooltip: S.of(context).swap,
            onPressed: () {
              final String oldStartText = startController.text;
              startController.text = destinationController.text;
              destinationController.text = oldStartText;
              onSwap!();
            },
            icon: const Icon(Icons.swap_vert),
          ),
        ],
      );
    }
    return timeline;
  }
}
