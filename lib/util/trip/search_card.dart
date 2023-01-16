import 'package:flutter/material.dart';

import 'package:timelines/timelines.dart';

import '../../account/models/profile.dart';
import '../../account/widgets/avatar.dart';
import '../../rides/models/ride.dart';
import '../../rides/pages/ride_detail_page.dart';
import '../custom_timeline_theme.dart';
import '../locale_manager.dart';
import '../profiles/profile_widget.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import 'trip_card.dart';

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
        )
      ],
    );
  }

  Widget buildDate() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(localeManager.formatDate(trip.startTime)),
        Text("${trip.price}€"),
      ],
    );
  }

  Widget buildProfile(driver) {
    return Row(
      children: [
        Avatar(driver),
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
              ProfileWidget(driver),
              const CustomRatingBarIndicator(rating: 3),
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
            builder: (context) => RideDetailPage.fromRide(trip),
          ),
        ),
        child: buildCardInfo(context, driver),
      ),
    );
  }
}
