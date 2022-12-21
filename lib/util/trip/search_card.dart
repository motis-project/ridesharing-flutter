import 'package:flutter/material.dart';
import 'package:flutter_app/account/models/profile.dart';
import 'package:flutter_app/rides/models/ride.dart';
import 'package:flutter_app/util/custom_timeline_theme.dart';
import 'package:flutter_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';
import '../../rides/pages/search_detail_page.dart';

class SearchCard extends TripCard<Ride> {
  const SearchCard(super.trip, {super.key});

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
        )
      ],
    );
  }

  Widget buildDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(formatDate(trip.startTime)),
        Text("${trip.price}\u{20AC} "),
      ],
    );
  }

  Widget buildProfile(driver) {
    return Row(
      children: [
        CircleAvatar(
          child: Text(driver.username[0]),
        ),
        const SizedBox(width: 5),
        Text(driver.username),
      ],
    );
  }

  Widget buildRanking() {
    return Row(
      children: const [
        Text("3"),
        Icon(
          Icons.star,
          color: Colors.amberAccent,
        ),
      ],
    );
  }

  Widget buildCardInfo(context, driver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: buildDate(),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: buildRoute(context),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildProfile(driver),
              buildRanking(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Profile driver = trip.drive!.driver!;

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const SearchDetailPage(),
          ),
        ),
        child: buildCardInfo(context, driver),
      ),
    );
  }
}
