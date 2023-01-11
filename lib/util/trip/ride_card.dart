import 'dart:math';

import 'package:flutter/material.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/custom_banner.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card_state.dart';
import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../drives/models/drive.dart';
import 'package:timelines/timelines.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../rides/pages/ride_detail_page.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import '../profiles/reviews/custom_rating_bar_size.dart';
import '../supabase.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RideCard extends TripCard<Ride> {
  const RideCard(super.trip, {super.key});

  @override
  State<RideCard> createState() => RideCardState();
}

class RideCardState extends TripCardState<RideCard> {
  Ride? ride;
  bool fullyLoaded = false;
  Profile? driver;

  static const String _driveQuery = '''
    *,
    driver: driver_id(
      *,
      reviews_received: reviews!reviews_receiver_id_fkey(
        *,
        writer: writer_id(*)
      ),
      profile_features(*)
    ),
    rides(
      *,
      rider: rider_id(*)
    )
  ''';

  @override
  void initState() {
    super.initState();
    setState(() {
      ride = widget.trip;
      super.trip = ride;
    });
    loadRide();
  }

  Future<void> loadRide() async {
    Ride trip = ride!;
    Map<String, dynamic> data = await supabaseClient.from('drives').select(_driveQuery).eq('id', trip.driveId).single();
    trip.drive = Drive.fromJson(data);
    setState(() {
      ride = trip;
      driver = trip.drive!.driver!;
      super.trip = ride;
      fullyLoaded = true;
    });
  }

  @override
  Widget buildTopRight() {
    return Row(
      children: [
        Text("${ride!.price}€"),
      ],
    );
  }

  @override
  Widget buildBottomLeft() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        children: [
          CircleAvatar(
            child: Text(driver!.username[0]),
          ),
          const SizedBox(width: 5),
          Text(driver!.username),
        ],
      ),
    );
  }

  @override
  Widget buildBottomRight() {
    List<Review>? reviews = ride!.drive!.driver!.reviewsReceived;
    AggregateReview aggregateReview =
        AggregateReview(rating: 0, comfortRating: 0, safetyRating: 0, reliabilityRating: 0, hospitalityRating: 0);
    if (reviews != null) {
      aggregateReview = AggregateReview.fromReviews(ride!.drive!.driver!.reviewsReceived!);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarSize.large),
    );
  }

  @override
  Widget buildRightSide() {
    List<ProfileFeature> profileFeatures = driver!.profileFeatures!;
    List<Icon> featureicons = <Icon>[];
    for (int i = 0; i < min(profileFeatures.length, 3); i++) {
      featureicons.add(profileFeatures[i].feature.getIcon(context));
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: featureicons,
    );
  }

  @override
  Widget build(BuildContext context) {
    return !fullyLoaded
        ? const Center(child: CircularProgressIndicator())
        : Card(
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RideDetailPage.fromRide(ride!),
                ),
              ),
              child: buildCardInfo(context),
            ),
          );
  }

  /*
  if(ride!.status == RideStatus.cancelledByDriver)
          CustomBanner(kind: CustomBannerKind.warning, text: Text("Drive has been cancelled"));
*/
  @override
  Widget buildbanner() {
    switch (ride!.status) {
      case RideStatus.pending:
        return CustomBanner(kind: CustomBannerKind.pending, text: S.of(context).pageRideDetailBannerRequested);
      case RideStatus.rejected:
        return CustomBanner(kind: CustomBannerKind.warning, text: S.of(context).pageRideDetailBannerRejected);
      case RideStatus.cancelledByDriver:
        return CustomBanner(kind: CustomBannerKind.error, text: S.of(context).pageRideDetailBannerCancelledByDriver);
      case RideStatus.cancelledByRider:
        return CustomBanner(kind: CustomBannerKind.error, text: S.of(context).pageRideDetailBannerCancelledByYou);
      default:
        return const SizedBox();
    }
  }
}
