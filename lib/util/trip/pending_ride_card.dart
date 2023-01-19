import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../custom_timeline_theme.dart';
import '../icon_widget.dart';
import '../locale_manager.dart';
import '../profiles/profile_widget.dart';
import '../supabase.dart';
import 'trip_card.dart';

class PendingRideCard extends TripCard<Ride> {
  final Function() reloadPage;
  final Drive drive;
  const PendingRideCard(super.trip, {super.key, required this.reloadPage, required this.drive});
  final Duration extraTime = const Duration(minutes: 5);

  @override
  State<PendingRideCard> createState() => _PendingRideCardState();
}

class _PendingRideCardState extends State<PendingRideCard> {
  @override
  Widget build(BuildContext context) {
    FixedTimeline timeline = FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: [
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(widget.trip.startTime)}  ${widget.trip.start}'),
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
            padding: const EdgeInsets.fromLTRB(8, 16, 0, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${localeManager.formatTime(widget.trip.endTime)}  ${widget.trip.end}'),
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

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ProfileWidget(widget.trip.rider!),
                Text("+${localeManager.formatDuration(widget.extraTime, shouldPadHours: false)}"),
              ],
            ),
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
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: timeline,
                    ),
                  ],
                ),
              ),
              ButtonBar(
                children: [
                  IconButton(
                    onPressed: (() => showApproveDialog(context)),
                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50.0),
                    tooltip: S.of(context).approve,
                  ),
                  IconButton(
                    onPressed: (() => showRejectDialog(context)),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
                    tooltip: S.of(context).reject,
                  ),
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
                child: Text("${widget.trip.price}€"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  buildSeatsIndicator() {
    Widget icon = Icon(
      Icons.chair,
      color: Theme.of(context).colorScheme.primary,
    );
    return IconWidget(icon: icon, count: widget.trip.seats);
  }

  void approveRide() async {
    await SupabaseManager.supabaseClient.rpc(
      'approve_ride',
      params: {'ride_id': widget.trip.id},
    );
    // todo: notify rider
    widget.reloadPage();
  }

  void rejectRide() async {
    await SupabaseManager.supabaseClient.rpc(
      'reject_ride',
      params: {'ride_id': widget.trip.id},
    );
    //todo: notify rider
    widget.reloadPage();
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
              if (widget.drive.isRidePossible(widget.trip)) {
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
