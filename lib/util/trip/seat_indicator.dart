import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../drives/models/drive.dart';
import 'trip.dart';

class SeatIndicator extends StatelessWidget {
  final Trip trip;

  const SeatIndicator(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> seatIcons;
    Widget text;

    if (trip is Drive) {
      int? maxUsedSeats = (trip as Drive).getMaxUsedSeats();
      seatIcons = List<Icon>.generate(
        trip.seats,
        (int index) => Icon(
          Icons.chair,
          color: maxUsedSeats != null && index < maxUsedSeats
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        ),
      );
      text = Text(
        "${maxUsedSeats ?? '?'}/${trip.seats} ${S.of(context).seats}",
        semanticsLabel: maxUsedSeats != null
            ? S.of(context).labelXOfYseats(maxUsedSeats, trip.seats)
            : S.of(context).labelUnknownSeats(trip.seats),
      );
    } else {
      seatIcons = List<Icon>.generate(
        trip.seats,
        (int index) => Icon(
          Icons.chair,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
      text = Text(S.of(context).seatsCount(trip.seats));
    }

    return MergeSemantics(
      child: Column(
        children: <Widget>[
          Row(children: seatIcons),
          text,
        ],
      ),
    );
  }
}
