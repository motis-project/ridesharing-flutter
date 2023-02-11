import 'package:flutter/material.dart';

import '../../drives/models/recurring_drive.dart';
import '../locale_manager.dart';
import 'seat_indicator.dart';
import 'trip.dart';
import 'trip_like.dart';

class TripOverview extends StatelessWidget {
  final TripLike trip;

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
          localeManager.formatTimeOfDay(trip.startTime),
          style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          localeManager.formatTimeOfDay(trip.endTime),
          style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );

    final Widget overview = Column(
      children: <Widget>[startDest, timeWidget, const SizedBox(height: 10.0), buildInfoRow(context)],
    );

    return overview;
  }

  Widget buildInfoRow(BuildContext context) {
    final List<Widget> infoRowWidgets = <Widget>[];

    final String dateText = trip is Trip
        ? localeManager.formatDate((trip as Trip).startDateTime)
        : 'Seit ${localeManager.formatDate((trip as RecurringDrive).startedAt)}';

    final Widget dateWidget = Text(
      dateText,
      style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
    );
    infoRowWidgets.add(dateWidget);

    infoRowWidgets.add(SeatIndicator(trip));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: infoRowWidgets,
    );
  }
}
