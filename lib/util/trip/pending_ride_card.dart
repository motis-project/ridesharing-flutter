import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/custom_timeline_theme.dart';
import 'package:motis_mitfahr_app/util/icon_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/supabase.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../locale_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PendingRideCard extends TripCard<Ride> {
  final Function() reloadPage;
  final Drive drive;
  const PendingRideCard(super.trip, {super.key, required this.reloadPage, required this.drive});

  @override
  Widget build(BuildContext context) {
    Widget timeLine = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: [
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(trip.startTime)}  ${trip.start}'),
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
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(trip.endTime)}  ${trip.end}'),
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            startConnector: CustomSolidLineConnector(),
          ),
        ),
      ],
    );

    buildSeatsIndicator() {
      Widget icon = Icon(
        Icons.chair,
        color: Theme.of(context).colorScheme.primary,
      );
      return IconWidget(icon: icon, count: trip.seats);
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ProfileWidget(trip.rider!),
          ),
          const Divider(
            thickness: 1,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    timeLine,
                  ],
                ),
              ),
              ButtonBar(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: (() => showApproveDialog(context)),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50.0),
                      tooltip: S.of(context).approve,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: (() => showRejectDialog(context)),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
                      tooltip: S.of(context).reject,
                    ),
                  )
                ],
              ),
            ],
          ),
          const Divider(
            thickness: 1,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: buildSeatsIndicator(),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("${trip.price}€"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void approveRide() async {
    await supabaseClient.from('rides').update({'status': RideStatus.approved.index}).eq('id', trip.id);
    // todo: notify rider
    reloadPage();
  }

  void rejectRide() async {
    await supabaseClient.from('rides').update({'status': RideStatus.rejected.index}).eq('id', trip.id);
    //todo: notify rider
    reloadPage();
  }

  showApproveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).cardPendingRideApproveDialogTitle),
        content: Text(S.of(context).cardPendingRideApproveDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: Text(S.of(context).yes),
            onPressed: () {
              // check if there are enough seats available
              if (drive.isRidePossible(trip)) {
                approveRide();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).cardPendingRideApproveDialogSuccessSnackbar),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).cardPendingRideApproveDialogErrorSnackbar),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).cardPendingRideRejectDialogTitle),
        content: Text(S.of(context).cardPendingRideRejectDialogMessage),
        actions: <Widget>[
          TextButton(
            child: Text(S.of(context).no),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text(S.of(context).yes),
            onPressed: () {
              rejectRide();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(S.of(context).cardPendingRideRejectDialogSuccessSnackBar),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
