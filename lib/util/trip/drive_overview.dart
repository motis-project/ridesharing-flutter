import 'package:flutter/material.dart';

import '../../drives/models/drive.dart';
import '../locale_manager.dart';
import 'seat_indicator.dart';

class DriveOverview extends StatelessWidget {
  final Drive drive;

  const DriveOverview(this.drive, {super.key});

  @override
  Widget build(BuildContext context) {
    final Widget date = Text(
      localeManager.formatDate(drive.startTime),
      style: Theme.of(context).textTheme.titleMedium,
    );

    final Widget timeWidget = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          localeManager.formatTime(drive.startTime),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
        ),
        Row(
          children: <Widget>[
            const Icon(Icons.access_time_outlined),
            const SizedBox(width: 4),
            Text(
              localeManager.formatDuration(drive.duration),
            ),
          ],
        ),
        Text(
          localeManager.formatTime(drive.endTime),
          style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
        ),
      ],
    );

    final Widget startDest = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Expanded(child: Text(drive.start, style: Theme.of(context).textTheme.titleLarge)),
        const SizedBox(width: 10.0),
        const Icon(Icons.east),
        const SizedBox(width: 10.0),
        Expanded(child: Text(drive.end, textAlign: TextAlign.right, style: Theme.of(context).textTheme.titleLarge)),
      ],
    );

    final Widget seatIndicator = SeatIndicator(drive);

    final Widget overview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        date,
        const SizedBox(height: 20.0),
        timeWidget,
        startDest,
        const SizedBox(height: 20.0),
        Row(children: <Widget>[seatIndicator]),
      ],
    );

    return overview;
  }
}
