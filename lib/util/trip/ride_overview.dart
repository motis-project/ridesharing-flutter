import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

import '../../rides/models/ride.dart';
import '../custom_timeline_theme.dart';
import '../locale_manager.dart';
import 'seat_indicator.dart';

class RideOverview extends StatelessWidget {
  final Ride ride;

  const RideOverview(this.ride, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget date = Text(
      localeManager.formatDate(ride.startTime),
      style: Theme.of(context).textTheme.titleMedium,
    );

    final Widget startDest = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: <Widget>[
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  localeManager.formatTime(ride.startTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    ride.start,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            endConnector: CustomSolidLineConnector(),
          ),
        ),
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.fromLTRB(10, 24, 0, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 4),
                      Text(
                        localeManager.formatDuration(ride.duration),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          node: const TimelineNode(
            startConnector: CustomSolidLineConnector(),
            endConnector: CustomSolidLineConnector(),
          ),
        ),
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  localeManager.formatTime(ride.endTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    ride.end,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            startConnector: CustomSolidLineConnector(),
          ),
        )
      ],
    );

    final Widget seatIndicator = SeatIndicator(ride);

    late final Widget price;
    price = Text(key: const Key('price'), '${ride.price?.toStringAsFixed(2)}€');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        date,
        const SizedBox(height: 20.0),
        startDest,
        const SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[seatIndicator, price],
        )
      ],
    );
  }
}
