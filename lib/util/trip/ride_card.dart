import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:motis_mitfahr_app/rides/models/ride.dart';
import 'package:motis_mitfahr_app/util/buttons/custom_banner.dart';
import 'package:motis_mitfahr_app/util/profiles/profile_widget.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card.dart';
import 'package:motis_mitfahr_app/util/trip/trip_card_state.dart';
import '../../account/models/profile.dart';
import '../../account/models/profile_feature.dart';
import '../../drives/models/drive.dart';

import '../../rides/pages/ride_detail_page.dart';
import '../profiles/reviews/custom_rating_bar_indicator.dart';
import '../profiles/reviews/custom_rating_bar_size.dart';
import '../supabase.dart';
import 'package:motis_mitfahr_app/account/models/review.dart';

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
      child: ProfileWidget(driver!),
    );
  }

  @override
  Widget buildBottomRight() {
    List<Review>? reviews = ride!.drive!.driver!.reviewsReceived;
    AggregateReview aggregateReview = AggregateReview(
        rating: 0,
        comfortRating: 0,
        safetyRating: 0,
        reliabilityRating: 0,
        hospitalityRating: 0,
        numberOfReviews: reviews!.length);
    if (reviews != null) {
      aggregateReview = AggregateReview.fromReviews(ride!.drive!.driver!.reviewsReceived!);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: CustomRatingBarIndicator(rating: aggregateReview.rating, size: CustomRatingBarSize.medium),
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
                child: ride!.status.isCancelled()
                    ? Stack(
                        children: [CustomBanner.error('cancelled'), buildCardInfo(context)],
                      )
                    : (ride!.status == RideStatus.pending)
                        ? Stack(
                            children: [CustomBanner.pending('pending'), buildCardInfo(context)],
                          )
                        : buildCardInfo(context)),
          );
  }
}
