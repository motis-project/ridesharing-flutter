import 'package:flutter/material.dart';
import 'package:flutter_app/drives/models/drive.dart';
import 'package:flutter_app/util/trip/trip.dart';
import 'package:intl/intl.dart';

class TripOverview extends StatelessWidget {
  final Trip trip;

  const TripOverview(this.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    Widget startDest = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trip.start),
              Text(
                DateFormat.Hm().format(trip.startTime),
                style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
              )
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(trip.end),
              Text(
                DateFormat.Hm().format(trip.endTime),
                style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
              )
            ],
          ),
        ),
      ],
    );

    List<Widget> infoRowWidgets = [];

    Widget dateWidget = Text(
      DateFormat('dd.MM.yyyy').format(trip.startTime),
      style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.w700),
    );
    infoRowWidgets.add(dateWidget);

    Widget seatIndicator = buildSeatIndicator(context);
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

  Widget buildSeatIndicator(BuildContext context) {
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
              : Colors.grey.shade500,
        ),
      );
      text = Text("${maxUsedSeats ?? '?'}/${trip.seats} Seats");
    } else {
      seatIcons = List.generate(
        trip.seats,
        (index) => Icon(
          Icons.chair,
          color: Theme.of(context).colorScheme.primary,
        ),
      );
      text = Text('${trip.seats} ${Intl.plural(trip.seats, one: 'Seat', other: 'Seats')}');
    }

    return Column(
      children: [
        Row(
          children: seatIcons,
        ),
        text,
      ],
    );
  }
}
