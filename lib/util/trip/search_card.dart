import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/account/models/profile.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/rides/pages/ride_detail_page.dart';
import 'package:motis_mitfahr_app/util/custom_timeline_theme.dart';
import 'package:motis_mitfahr_app/util/locale_manager.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/profiles/reviews/custom_rating_bar_indicator.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:timelines/timelines.dart';

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
              CustomRatingBarIndicator(rating: 3),
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
