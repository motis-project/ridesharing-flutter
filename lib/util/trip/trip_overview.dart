import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/drives/models/drive.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TripOverview extends StatelessWidget {
  final Trip trip;

  const TripOverview(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget startDest = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: MergeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(trip.start),
                Text(
                  localeManager.formatTime(trip.startTime),
                  style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
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
              children: [
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

    List<Widget> infoRowWidgets = [];

    Widget dateWidget = Text(
      localeManager.formatDate(trip.startTime),
      style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
    );
    infoRowWidgets.add(dateWidget);

    Widget seatIndicator = buildSeatIndicator(context, trip);
    infoRowWidgets.add(seatIndicator);

    Widget infoRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: infoRowWidgets,
    );

    Widget overview = Column(
      children: [startDest, const SizedBox(height: 10.0), infoRow],
    );

    return overview;
  }

  static Widget buildSeatIndicator(BuildContext context, Trip trip) {
    List<Widget> seatIcons;
    Widget text;

    if (trip is Drive) {
      int? maxUsedSeats = (trip as Drive).getMaxUsedSeats();
      seatIcons = List.generate(
        trip.seats,
        (index) => Icon(
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
      seatIcons = List.generate(
        trip.seats,
        (index) => Icon(
          Icons.chair,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
      text = Text(S.of(context).seatsCount(trip.seats));
    }

    return MergeSemantics(
      child: Column(
        children: [
          Row(children: seatIcons),
          text,
        ],
      ),
    );
  }
}
