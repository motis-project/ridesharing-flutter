import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../drives/models/recurring_drive.dart';
import 'seat_indicator.dart';
import 'trip_card.dart';

class RecurringDriveEmptyCard extends TripCard<RecurringDrive> {
  const RecurringDriveEmptyCard(super.trip, {super.key});

  @override
  State<RecurringDriveEmptyCard> createState() => RecurringDriveEmptyCardState();
}

class RecurringDriveEmptyCardState extends TripCardState<RecurringDrive, RecurringDriveEmptyCard> {
  late RecurringDrive recurringDrive;

  @override
  void initState() {
    super.initState();

    setState(() {
      recurringDrive = widget.trip;
      trip = recurringDrive;
    });
  }

  // @override
  // void didUpdateWidget(RecurringDriveEmptyCard oldWidget) {
  //   if (!trip.equals(widget.trip)) {
  //     loadDrive();
  //   }
  //   super.didUpdateWidget(oldWidget);
  // }

  // No-op because the tap is already handled by the parent widget.
  @override
  void Function()? get onTap => null;

  @override
  Widget buildRightSide() {
    return SeatIndicator(trip);
  }

  @override
  Widget buildTopLeft() {
    return Flexible(
      child: Text(
        recurringDrive.isStopped
            ? S.of(context).pageRecurringDriveDetailUpcomingDrivesStopped
            : S.of(context).pageRecurringDriveDetailUpcomingDrivesEmpty,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Color get statusColor => Theme.of(context).colorScheme.error;
}
