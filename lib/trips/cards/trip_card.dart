import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timelines/timelines.dart';

import '../../managers/locale_manager.dart';
import '../models/trip_like.dart';
import '../util/custom_timeline_theme.dart';

abstract class TripCard<T extends TripLike> extends StatefulWidget {
  final T trip;
  final bool loadData;
  const TripCard(this.trip, {super.key, this.loadData = true});
}

abstract class TripCardState<T extends TripLike, U extends TripCard<T>> extends State<U> {
  late T trip;

  BorderRadius cardBorder = const BorderRadius.only(
    bottomRight: Radius.circular(10),
    topRight: Radius.circular(10),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      color: statusColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: <Widget>[
          Container(
            foregroundDecoration: pickDecoration(),
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: cardBorder,
            ),
            margin: const EdgeInsets.only(left: 10),
            child: buildCardInfo(),
          ),
          if (onTap != null)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: Semantics(
                  button: true,
                  tooltip: S.of(context).openDetails,
                  child: InkWell(
                    onTap: onTap,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void Function()? get onTap;

  EdgeInsets get middlePadding => const EdgeInsets.fromLTRB(10, 24, 0, 24);

  FixedTimeline buildRoute() {
    return FixedTimeline(
      theme: CustomTimelineTheme.of(context),
      children: <Widget>[
        TimelineTile(
          contents: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  localeManager.formatTimeOfDay(trip.startTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    key: const Key('start'),
                    trip.start,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
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
              children: <Widget>[
                Expanded(
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.access_time_outlined),
                      const SizedBox(width: 4),
                      Text(
                        localeManager.formatDuration(trip.duration),
                        key: const Key('duration'),
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
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: <Widget>[
                Text(
                  localeManager.formatTimeOfDay(trip.destinationTime),
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.normal),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    key: const Key('destination'),
                    trip.destination,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                )
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
        children: <Widget>[
          buildTopLeft(),
          const SizedBox(width: 10),
          buildTopRight(),
        ],
      ),
    );
  }

  Widget buildBottom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        buildBottomLeft(),
        const SizedBox(width: 10),
        buildBottomRight(),
      ],
    );
  }

  Widget buildCardInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        buildTop(),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), child: buildRoute()),
        buildBottom(),
      ],
    );
  }

  Widget buildTopLeft() {
    return const SizedBox();
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

  Color get statusColor => Theme.of(context).cardColor;

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
