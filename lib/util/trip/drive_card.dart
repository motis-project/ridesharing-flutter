import 'package:flutter/material.dart';

import 'package:flutter_app/util/trip/trip_card.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import 'package:timelines/timelines.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard({super.key, required super.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const DriveDetailPage(),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(formatDate(trip.startTime)),
            ),
            const Divider(),
            FixedTimeline(
              theme: TimelineTheme.of(context).copyWith(
                nodePosition: 0.05,
                color: Colors.black,
              ),
              children: [
                TimelineTile(
                  contents: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${formatTime(trip.startTime)}  ${trip.start}'),
                      ],
                    ),
                  ),
                  node: const TimelineNode(
                    indicator: OutlinedDotIndicator(),
                    endConnector: SolidLineConnector(),
                  ),
                ),
                TimelineTile(
                  contents: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${formatTime(trip.endTime)}  ${trip.end}'),
                      ],
                    ),
                  ),
                  node: const TimelineNode(
                    indicator: OutlinedDotIndicator(),
                    startConnector: SolidLineConnector(),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
