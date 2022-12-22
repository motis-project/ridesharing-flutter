import 'package:flutter/material.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/supabase.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';
import '../../rides/models/ride.dart';

class PendingRideCard extends TripCard<Ride> {
  final Function() reloadPage;
  const PendingRideCard(super.trip, {super.key, required this.reloadPage});

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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              children: [
                FixedTimeline(
                  theme: CustomTimelineTheme.of(context),
                  children: [
                    TimelineTile(
                      contents: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${formatTime(trip.startTime)}  ${trip.start}'),
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
                            Text('${formatTime(trip.endTime)}  ${trip.end}'),
                          ],
                        ),
                      ),
                      node: const TimelineNode(
                        indicator: CustomOutlinedDotIndicator(),
                        startConnector: CustomSolidLineConnector(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ButtonBar(
            children: [
              IconButton(
                onPressed: (() => showApproveDialog(context)),
                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 50.0),
              ),
              IconButton(
                onPressed: (() => showRejectDialog(context)),
                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 50.0),
              ),
            ],
          ),
        ],
      ),
    );
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
              if (trip.drive!.getMaxUsedSeatsforRide(trip) + trip.seats > trip.drive!.seats) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Not enough seats available"),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              } else {
                approveRide();
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ride confirmed"),
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
