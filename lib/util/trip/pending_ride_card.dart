import 'package:flutter/material.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/profiles/profile_widget.dart';
import 'package:flutter_app/util/profiles/reviews/custom_rating_bar_indicator.dart';
import 'package:flutter_app/util/profiles/reviews/custom_rating_bar_size.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';
import '../../drives/models/drive.dart';
import '../../rides/models/ride.dart';
import '../locale_manager.dart';

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
    Widget ratingBar = Padding(
      padding: const EdgeInsets.all(8.0),
      child: CustomRatingBarIndicator(
        rating: trip.rider!.getAggregateReview().rating,
        size: CustomRatingBarSize.medium,
      ),
    );

    return Card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProfileWidget(trip.rider!),
              ),
              ratingBar,
            ],
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
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: (() => showRejectDialog(context)),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
                    ),
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
                child: Text("Seats: ${trip.seats.toString()}"),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text("Price: ${trip.price.toString()}"),
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
        title: const Text("Confirm Ride"),
        content: const Text("Are you sure you want to confirm this ride?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          TextButton(
            child: const Text("Confirm"),
            onPressed: () {
              // check if there are enough seats available
              if (drive.isRidePossible(trip)) {
                approveRide();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ride confirmed"),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Not enough seats available"),
                    duration: Duration(seconds: 2),
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
        title: const Text("Reject Ride"),
        content: const Text("Are you sure you want to reject this ride?"),
        actions: <Widget>[
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text("Reject"),
            onPressed: () {
              rejectRide();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Ride rejected"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
