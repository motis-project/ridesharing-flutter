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
        Expanded(child: Text(trip.start)),
        const SizedBox(width: 10.0),
        const Icon(Icons.arrow_forward_rounded),
        const SizedBox(width: 10.0),
        Expanded(child: Text(trip.end, textAlign: TextAlign.right)),
      ],
    );

    final Widget timeWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          localeManager.formatTime(trip.startTime),
          style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          localeManager.formatTime(trip.endTime),
          style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
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
      children: <Widget>[startDest, timeWidget, const SizedBox(height: 10.0), infoRow],
    );

    return overview;
  }
}
