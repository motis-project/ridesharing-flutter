import 'package:flutter/material.dart';

import '../locale_manager.dart';
import 'seat_indicator.dart';
import 'trip.dart';

class TripOverview extends StatelessWidget {
  final Trip trip;

  const TripOverview(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget startDest = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(trip.start),
                Text(
                  localeManager.formatTime(trip.startTime),
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
                )
              ],
            ),
          ),
        ),
        const Icon(Icons.arrow_forward_rounded),
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(trip.end),
                Text(
                  localeManager.formatTime(trip.endTime),
                  style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
                )
              ],
            ),
          ),
        ),
      ],
    );

    final List<Widget> infoRowWidgets = <Widget>[];

    final Widget dateWidget = Text(
      localeManager.formatDate(trip.startTime),
      style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
    );
    infoRowWidgets.add(dateWidget);

    infoRowWidgets.add(SeatIndicator(trip));

    final Widget infoRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: infoRowWidgets,
    );

    final Widget overview = Column(
      children: <Widget>[startDest, const SizedBox(height: 10.0), infoRow],
    );

    return overview;
  }
}
