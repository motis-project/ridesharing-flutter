import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/util/custom_timeline_theme.dart';

import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import '../../drives/models/drive.dart';
import '../../drives/pages/drive_detail_page.dart';
import 'package:timelines/timelines.dart';
import '../locale_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DriveCard extends TripCard<Drive> {
  const DriveCard(super.trip, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Semantics(
        button: true,
        tooltip: S.of(context).openDetails,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => DriveDetailPage.fromDrive(trip),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(localeManager.formatDate(trip.startTime)),
              ),
              const Divider(),
              FixedTimeline(
                theme: CustomTimelineTheme.of(context),
                children: [
                  TimelineTile(
                    contents: Padding(
                      padding: const EdgeInsets.all(32.0),
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
                      padding: const EdgeInsets.all(32.0),
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
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
