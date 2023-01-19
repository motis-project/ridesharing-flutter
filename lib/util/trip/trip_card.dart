import 'package:flutter/material.dart';
import 'package:timelines/timelines.dart';

import '../custom_timeline_theme.dart';
import '../locale_manager.dart';
import 'trip.dart';

abstract class TripCard<T extends Trip> extends StatefulWidget {
  final T trip;
  const TripCard(this.trip, {super.key});
}

abstract class TripCardState<T extends TripCard> extends State<T> {
  Trip? trip;

  BorderRadius cardBorder = const BorderRadius.only(
    bottomRight: Radius.circular(10),
    topRight: Radius.circular(10),
  );

  FixedTimeline buildRoute(context) {
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
                        localeManager.formatDuration(trip!.duration, true),
                      ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(localeManager.formatDate(trip!.startTime)),
          buildTopRight(),
        ],
      ),
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

  Widget buildBottomLeft() {
    return const SizedBox();
  }

  Widget buildBottomRight() {
    return const SizedBox();
  }

  Widget buildTopRight() {
    return const SizedBox();
  }

  Widget buildRightSide() {
    return const SizedBox();
  }
}
