import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../custom_timeline_theme.dart';
import '../locale_manager.dart';
import 'trip.dart';

abstract class TripCard<T extends Trip> extends StatefulWidget {
  final T trip;
  const TripCard(this.trip, {super.key});
}

abstract class TripCardState<T extends TripCard> extends State<T> {
  late Trip trip;

  BorderRadius cardBorder = const BorderRadius.only(
    bottomRight: Radius.circular(10),
    topRight: Radius.circular(10),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      color: pickStatusColor(),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Container(
            foregroundDecoration: pickDecoration(),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: cardBorder,
            ),
            margin: const EdgeInsets.only(left: 10),
            child: buildCardInfo(context),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Semantics(
                button: true,
                tooltip: S.of(context).openDetails,
                child: InkWell(
                  onTap: onTap(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void Function()? onTap();

  EdgeInsets get middlePadding => const EdgeInsets.all(16);

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
                  '${localeManager.formatTime(trip.startTime)}  ${trip.start}',
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
            padding: middlePadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 4),
                      Text(
                        localeManager.formatDuration(trip.duration),
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
                  '${localeManager.formatTime(trip.endTime)}  ${trip.end}',
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
          buildTopLeft(),
          buildTopRight(),
        ],
      ),
    );
  }

  Widget buildBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildBottomLeft(),
        buildBottomRight(),
      ],
    );
  }

  Widget buildCardInfo(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTop(),
        Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), child: buildRoute(context)),
        buildBottom(),
      ],
    );
  }

  Widget buildTopLeft() {
    return Text(localeManager.formatDate(trip.startTime));
  }

  Widget buildTopRight() {
    return const SizedBox();
  }

  Widget buildBottomLeft() {
    return const SizedBox();
  }

  Widget buildBottomRight() {
    return const SizedBox();
  }

  Widget buildRightSide() {
    return const SizedBox();
  }

  Color pickStatusColor() {
    return Theme.of(context).cardColor;
  }

  BoxDecoration pickDecoration() {
    return BoxDecoration(
      borderRadius: cardBorder,
    );
  }

  BoxDecoration get disabledDecoration => BoxDecoration(
        color: Colors.grey,
        borderRadius: cardBorder,
        backgroundBlendMode: BlendMode.multiply,
      );
}
