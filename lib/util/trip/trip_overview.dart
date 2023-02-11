import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

import '../../drives/models/recurring_drive.dart';
import '../../rides/models/ride.dart';
import '../custom_timeline_theme.dart';
import '../locale_manager.dart';
import 'seat_indicator.dart';
import 'trip.dart';
import 'trip_like.dart';

class TripOverview extends StatelessWidget {
  final TripLike trip;

  const TripOverview(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget startDest = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: <Widget>[
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  localeManager.formatTimeOfDay(trip.startTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    trip.start,
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
                    children: const <Widget>[
                      Icon(Icons.access_time_outlined),
                      SizedBox(width: 4),
                      Text(
                        'PLACEHOLDER',
                        //TODO: localeManager.formatDurationOfDay(trip.duration),
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
                  localeManager.formatTimeOfDay(trip.endTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    trip.end,
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

    final String dateText = (trip is Trip)
        ? localeManager.formatDate((trip as Trip).startDateTime)
        : 'Seit ${localeManager.formatDate((trip as RecurringDrive).startedAt)}';
    final Widget date = Text(
      dateText,
      style: Theme.of(context).textTheme.titleMedium,
    );

    final Widget seatIndicator = SeatIndicator(trip);

    late final Widget price;
    if (trip is Ride) {
      price = Text(key: const Key('price'), '${(trip as Ride).price?.toStringAsFixed(2)}€');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        date,
        const SizedBox(height: 20.0),
        startDest,
        const SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[seatIndicator, if (trip is Ride) price],
        )
      ],
    );
  }
}
