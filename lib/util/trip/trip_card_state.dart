import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/trip/trip.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';

import '../custom_timeline_theme.dart';
import '../locale_manager.dart';

abstract class TripCardState<T extends TripCard> extends State<T> {
  Trip? trip;

  FixedTimeline buildRoute(context) {
    Duration duration = trip!.endTime.difference(trip!.startTime);
    return FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: [
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localeManager.formatTime(trip!.startTime)}  ${trip!.start}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 4),
                      Text(
                          "${duration.inHours.toString().padLeft(2, "0")}:${(duration.inMinutes % 60).toString().padLeft(2, "0")}"),
                    ],
                  ),
                ),
                buildRightSide(),
              ],
            ),
          ),
          node: const TimelineNode(
            startConnector: CustomSolidLineConnector(),
            endConnector: CustomSolidLineConnector(),
          ),
        ),
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${localeManager.formatTime(trip!.endTime)}  ${trip!.end}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          node: const TimelineNode(
            indicator: CustomOutlinedDotIndicator(),
            startConnector: CustomSolidLineConnector(),
          ),
        )
      ],
    );
  }

  Widget buildTop() {
    return Stack(
      fit: StackFit.loose,
      children: [
        buildbanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(localeManager.formatDate(trip!.startTime)),
              buildTopRight(),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildCardInfo(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTop(),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), child: buildRoute(context)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildBottomLeft(),
            buildBottomRight(),
          ],
        ),
      ],
    );
  }

  Widget buildbanner();
  Widget buildBottomLeft();
  Widget buildBottomRight();
  Widget buildTopRight();
  Widget buildRightSide();
}
